// ContactViewModel.swift
// BirthdayUI

import Foundation
import Combine
import WidgetKit
import Contacts

// Counter key for "birthdays remembered"
private let rememberedCountKey = "BirthdayRememberedCount"

@available(iOS 17.0, *)
final class ContactViewModel: ObservableObject {

    // MARK: - Published state for SwiftUI
    @Published var contacts: [Contact]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Number of birthday messages the user has actually sent
    @Published var rememberedBirthdaysCount: Int = 0

    // MARK: - Private
    private let contactsManager = ContactsManager()
    private var hasCompletedInitialLoad = false
    private var isFetchInFlight = false

    // MARK: - Init / Deinit
    init(contacts: [Contact] = []) {
        self.contacts = contacts
        self.rememberedBirthdaysCount = UserDefaults.standard.integer(forKey: rememberedCountKey)

        // Listen for "message sent" events from the composer (BirthdayMessageViewModel posts this)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBirthdayMessageSent),
            name: .birthdayMessageSent,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .birthdayMessageSent, object: nil)
    }

    // MARK: - Loading contacts
    /// Loads contacts once on launch. Pass `force: true` to refresh from the address book.
    func loadContacts(force: Bool = false) {
        if isFetchInFlight { return }
        if hasCompletedInitialLoad && !force { return }

        isFetchInFlight = true
        // Only show the full-screen loader on the first empty load — avoids
        // wiping the home screen (and triggering NavigationLink bugs) on return.
        if contacts.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        contactsManager.fetchContactsSortedByBirthday { [weak self] result in
            guard let self else { return }
            self.isFetchInFlight = false
            self.isLoading = false
            self.hasCompletedInitialLoad = true

            switch result {
            case .success(let fetchedContacts):
                self.contacts = fetchedContacts

                // 🔔 Ask notification permission if needed (only prompts once)
                BirthdayNotificationManager.shared.requestAuthorizationIfNeeded()

                // 🔔 Schedule today’s birthday alerts at the user’s chosen time
                let settings = AppSettings.shared
                if settings.notificationsEnabled {
                    BirthdayNotificationManager.shared.refreshDailySchedule(
                        contacts: self.contactsWithBirthday,
                        fireHour: settings.notificationHour,
                        fireMinute: settings.notificationMinute
                    )
                } else {
                    BirthdayNotificationManager.shared.clearAllBirthdayNotifications()
                }

                // 🔁 Update widget data
                self.updateWidgetData()

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                print("Error fetching contacts: \(error)")
            }
        }
    }

    // MARK: - Remembered counter
    /// Call this when a birthday message is successfully sent.
    func incrementRememberedBirthdays() {
        rememberedBirthdaysCount += 1
        UserDefaults.standard.set(rememberedBirthdaysCount, forKey: rememberedCountKey)
        updateWidgetData()
    }

    @objc private func onBirthdayMessageSent() {
        incrementRememberedBirthdays()
    }

    // MARK: - Derived collections
    /// Contacts sorted by next upcoming birthday.
    var sortedUpcoming: [Contact] {
        contacts.sorted { c1, c2 in
            guard let d1 = c1.comparableBirthday,
                  let d2 = c2.comparableBirthday else {
                // contacts with a birthday come first
                return c1.comparableBirthday != nil
            }
            return d1.nextBirthday() < d2.nextBirthday()
        }
    }

    /// Only contacts that actually have a birthday.
    var contactsWithBirthday: [Contact] {
        sortedUpcoming.filter { $0.comparableBirthday != nil }
    }

    /// Contacts missing a birthday.
    var contactsWithoutBirthday: [Contact] {
        sortedUpcoming.filter { $0.comparableBirthday == nil }
    }

    /// Number of *upcoming* birthdays that still happen in the current month.
    var birthdaysThisMonthCount: Int {
        birthdaysThisMonth.count
    }

    /// The actual contacts whose *next* birthday is still in this month.
    var birthdaysThisMonth: [Contact] {
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.month, .year], from: now)

        return contactsWithBirthday.filter { contact in
            guard let days = contact.daysToBirthday,
                  let nextBirthdayDate = calendar.date(byAdding: .day, value: days, to: now)
            else { return false }

            let nextComponents = calendar.dateComponents([.month, .year], from: nextBirthdayDate)
            return nextComponents.month == currentComponents.month &&
                   nextComponents.year == currentComponents.year
        }
    }

    // MARK: - Filtering helpers
    func contactsPerDate(date: Date) -> [Contact] {
        contactsWithBirthday.filter { $0.isObserved(on: date) }
    }
    
    /// True when any contact observes a birthday on this date (for calendar dots).
    func hasBirthday(on dateComponents: DateComponents) -> Bool {
        guard let date = Calendar.current.date(from: dateComponents) else { return false }
        return contactsWithBirthday.contains { $0.isObserved(on: date) }
    }

    func contactsPerMonth(monthName: String) -> [Contact] {
        let df = DateFormatter()
        df.dateFormat = "MMMM"
        guard let monthDate = df.date(from: monthName.capitalized) else { return [] }
        let monthNumber = Calendar.current.component(.month, from: monthDate)

        return contactsWithBirthday.filter {
            guard let contactMonth = $0.birthday?.month else { return false }
            return contactMonth == monthNumber
        }
    }

    // MARK: - Widget data
    func updateWidgetData() {
        let sorted = contactsWithBirthday.sorted {
            ($0.daysToBirthday ?? Int.max) < ($1.daysToBirthday ?? Int.max)
        }
        let next = sorted.first

        let data = BirthdayWidgetData(
            nextName: next?.name,
            daysToNext: next?.daysToBirthday,
            upcomingThisMonth: birthdaysThisMonthCount,
            rememberedCount: rememberedBirthdaysCount
        )

        // MUST match your App Group ID on both app + widget targets
        let defaults = UserDefaults(suiteName: "group.com.archit.BirthdayPal")
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: "BirthdayWidgetData")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
