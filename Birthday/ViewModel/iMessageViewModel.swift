// ContactViewModel.swift
// BirthdayUI

import Foundation
import Combine
import WidgetKit
import Contacts
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BirthdayPal", category: "Contacts")

private let rememberedCountKey = "BirthdayRememberedCount"

final class ContactViewModel: ObservableObject {

    // MARK: - Published state for SwiftUI

    /// Contacts that have a birthday, sorted by next observance (cached).
    @Published private(set) var contactsWithBirthday: [Contact] = []
    /// Loaded on demand for the add-missing flow.
    @Published var contactsWithoutBirthday: [Contact] = []

    /// Upcoming birthdays for the home carousel, sorted by next observance.
    @Published private(set) var upcomingPreview: [Contact] = []
    @Published private(set) var todaysBirthdays: [Contact] = []
    @Published private(set) var birthdaysThisMonth: [Contact] = []
    @Published private(set) var birthdaysThisMonthCount: Int = 0

    /// True only while the first birthday fetch is in flight (Coming Up section).
    @Published var isLoadingBirthdays: Bool = true
    @Published var isLoadingMissing: Bool = false
    @Published var errorMessage: String?

    @Published var rememberedBirthdaysCount: Int = 0

    // MARK: - Private

    private let contactsManager = ContactsManager()
    private var hasCompletedInitialBirthdayLoad = false
    private var hasLoadedMissing = false
    private var isBirthdayFetchInFlight = false
    private var isMissingFetchInFlight = false

    /// month (1...12) → contacts with birthday in that month
    private var contactsByMonth: [Int: [Contact]] = [:]
    /// Observance keys for the current calendar year: month * 100 + day
    private var observanceDayKeys: Set<Int> = []

    // MARK: - Init / Deinit

    init(contacts: [Contact] = []) {
        if !contacts.isEmpty {
            let enriched = contacts.map { $0.enrichingCaches() }
            applyBirthdayContacts(enriched, softMerge: false)
            isLoadingBirthdays = false
            hasCompletedInitialBirthdayLoad = true
        }
        self.rememberedBirthdaysCount = UserDefaults.standard.integer(forKey: rememberedCountKey)

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

    // MARK: - Loading

    /// Loads birthday contacts (fast path). Pass `force: true` to refresh from the address book.
    func loadContacts(force: Bool = false) {
        if isBirthdayFetchInFlight { return }
        if hasCompletedInitialBirthdayLoad && !force { return }

        isBirthdayFetchInFlight = true
        // Keep showing existing cards during refresh; only spin on true first load.
        if contactsWithBirthday.isEmpty {
            isLoadingBirthdays = true
        }
        errorMessage = nil

        contactsManager.fetchContacts(scope: .withBirthdaysOnly) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let fetched):
                self.applyBirthdayContacts(fetched, softMerge: true)
                self.scheduleNotificationsAndWidgets()

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                logger.error("Error fetching contacts: \(error.localizedDescription, privacy: .public)")
            }

            // Flip loading last so observers (deep links) see contacts already applied.
            self.isBirthdayFetchInFlight = false
            self.isLoadingBirthdays = false
            self.hasCompletedInitialBirthdayLoad = true
        }
    }

    /// Loads contacts missing birthdays (add-missing). Call when that screen appears.
    func loadMissingBirthdayContactsIfNeeded(force: Bool = false) {
        if isMissingFetchInFlight { return }
        if hasLoadedMissing && !force { return }

        isMissingFetchInFlight = true
        if contactsWithoutBirthday.isEmpty {
            isLoadingMissing = true
        }

        contactsManager.fetchContacts(scope: .missingBirthdaysOnly) { [weak self] result in
            guard let self else { return }
            self.isMissingFetchInFlight = false
            self.isLoadingMissing = false
            self.hasLoadedMissing = true

            switch result {
            case .success(let fetched):
                self.contactsWithoutBirthday = Self.mergePreservingIdentity(
                    existing: self.contactsWithoutBirthday,
                    fetched: fetched
                )
            case .failure(let error):
                logger.error("Error fetching contacts without birthdays: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func contact(withId id: String) -> Contact? {
        contactsWithBirthday.first { $0.id == id }
            ?? contactsWithoutBirthday.first { $0.id == id }
    }

    // MARK: - Remembered counter

    func incrementRememberedBirthdays() {
        rememberedBirthdaysCount += 1
        UserDefaults.standard.set(rememberedBirthdaysCount, forKey: rememberedCountKey)
        updateWidgetData()
    }

    @objc private func onBirthdayMessageSent() {
        incrementRememberedBirthdays()
    }

    // MARK: - Filtering helpers (use caches)

    func contactsPerDate(date: Date) -> [Contact] {
        contactsWithBirthday.filter { $0.isObserved(on: date) }
    }

    func hasBirthday(on dateComponents: DateComponents) -> Bool {
        guard let month = dateComponents.month, let day = dateComponents.day else { return false }
        // Leap-day edge: Feb 29 people observe on Feb 28 in non-leap years — keys include that.
        if observanceDayKeys.contains(month * 100 + day) {
            return true
        }
        // Fallback for year mismatch / rare cases
        guard let date = Calendar.current.date(from: dateComponents) else { return false }
        return contactsWithBirthday.contains { $0.isObserved(on: date) }
    }

    func contactsPerMonth(monthName: String) -> [Contact] {
        let df = DateFormatter()
        df.dateFormat = "MMMM"
        guard let monthDate = df.date(from: monthName.capitalized) else { return [] }
        let monthNumber = Calendar.current.component(.month, from: monthDate)
        return contactsByMonth[monthNumber] ?? []
    }

    // MARK: - Private helpers

    private func applyBirthdayContacts(_ fetched: [Contact], softMerge: Bool) {
        let next = softMerge
            ? Self.mergePreservingIdentity(existing: contactsWithBirthday, fetched: fetched)
            : fetched
        contactsWithBirthday = next
        rebuildDerivedCaches()
    }

    private func rebuildDerivedCaches() {
        let list = contactsWithBirthday
        upcomingPreview = list
        todaysBirthdays = list.filter { $0.daysToBirthday == 0 }

        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        birthdaysThisMonth = list.filter { contact in
            guard let days = contact.daysToBirthday,
                  let next = calendar.date(byAdding: .day, value: days, to: now)
            else { return false }
            let comps = calendar.dateComponents([.month, .year], from: next)
            return comps.month == currentMonth && comps.year == currentYear
        }
        birthdaysThisMonthCount = birthdaysThisMonth.count

        var byMonth: [Int: [Contact]] = [:]
        var dayKeys: Set<Int> = []
        for contact in list {
            if let month = contact.birthday?.month {
                byMonth[month, default: []].append(contact)
            }
            if let observance = contact.observanceDate(in: currentYear) {
                let m = calendar.component(.month, from: observance)
                let d = calendar.component(.day, from: observance)
                dayKeys.insert(m * 100 + d)
            }
        }
        contactsByMonth = byMonth
        observanceDayKeys = dayKeys
    }

    private func scheduleNotificationsAndWidgets() {
        let settings = AppSettings.shared
        if settings.notificationsEnabled {
            BirthdayNotificationManager.shared.refreshDailySchedule(
                contacts: contactsWithBirthday
            )
        } else {
            BirthdayNotificationManager.shared.clearAllBirthdayNotifications()
        }

        updateWidgetData()
    }

    private static func mergePreservingIdentity(existing: [Contact], fetched: [Contact]) -> [Contact] {
        let oldById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        return fetched.map { new in
            guard let old = oldById[new.id] else { return new }
            if old.name == new.name,
               old.phoneNumber == new.phoneNumber,
               old.birthday == new.birthday,
               old.thumbnailData == new.thumbnailData,
               old.cachedDaysUntil == new.cachedDaysUntil,
               old.cachedAgeTurning == new.cachedAgeTurning {
                return old
            }
            return new
        }
    }

    private func updateWidgetData() {
        let next = contactsWithBirthday.first
        let data = BirthdayWidgetData(
            nextName: next?.name,
            daysToNext: next?.daysToBirthday,
            upcomingThisMonth: birthdaysThisMonthCount,
            rememberedCount: rememberedBirthdaysCount,
            nextContactID: next?.id,
            nextThumbnail: next?.thumbnailData
        )

        let defaults = UserDefaults(suiteName: "group.com.archit.BirthdayPal")
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: "BirthdayWidgetData")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
