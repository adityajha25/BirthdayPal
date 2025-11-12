//
//  ContactViewModel.swift
//  BirthdayUI
//
//  Created by Jaden Tran on 11/3/25.
//

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

    // Number of birthday messages the user has actually sent
    @Published var rememberedBirthdaysCount: Int = 0

    // MARK: - Private

    private let contactsManager = ContactsManager()

    // MARK: - Init

    init(contacts: [Contact] = []) {
        self.contacts = contacts
        // Load remembered count from UserDefaults (defaults to 0 if not set)
        self.rememberedBirthdaysCount = UserDefaults.standard.integer(forKey: rememberedCountKey)
    }

    // MARK: - Loading contacts

    func loadContacts() {
        isLoading = true
        errorMessage = nil

        contactsManager.fetchContactsSortedByBirthday { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let fetchedContacts):
                    self.contacts = fetchedContacts
                    // update widget whenever contacts refresh
                    self.updateWidgetData()

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error fetching contacts: \(error)")
                }
            }
        }
    }

    // MARK: - Remembered counter

    /// Call this when a birthday message is successfully sent.
    func incrementRememberedBirthdays() {
        rememberedBirthdaysCount += 1
        UserDefaults.standard.set(rememberedBirthdaysCount, forKey: rememberedCountKey)

        // Also refresh the widget so the remembered count updates there too
        updateWidgetData()
    }


    // MARK: - Derived collections

    /// Contacts sorted by next upcoming birthday.
    var sortedUpcoming: [Contact] {
        contacts.sorted { c1, c2 in
            guard let d1 = c1.comparableBirthday,
                  let d2 = c2.comparableBirthday else {
                // a contact with a birthday comes after one without
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
        let calendar = Calendar.current
        let now = Date()

        let currentComponents = calendar.dateComponents([.month, .year], from: now)

        return contactsWithBirthday.filter { contact in
            // daysToBirthday = days from *today* to their next birthday
            guard let days = contact.daysToBirthday,
                  let nextBirthdayDate = calendar.date(byAdding: .day, value: days, to: now)
            else {
                return false
            }

            let nextComponents = calendar.dateComponents([.month, .year], from: nextBirthdayDate)

            // Only count if the *next* birthday lands in this month & year
            return nextComponents.month == currentComponents.month &&
                   nextComponents.year == currentComponents.year
        }.count
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

    // MARK: - Filtering helpers for other screens

    func contactsPerDate(date: Date) -> [Contact] {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        let targetDay = calendar.component(.day, from: date)

        return contactsWithBirthday.filter {
            guard let birthday = $0.birthday else { return false }
            return birthday.month == targetMonth && birthday.day == targetDay
        }
    }

    func contactsPerMonth(monthName: String) -> [Contact] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"

        guard let monthDate = dateFormatter.date(from: monthName.capitalized) else {
            return []
        }

        let monthNumber = Calendar.current.component(.month, from: monthDate)

        return contactsWithBirthday.filter {
            guard let contactMonth = $0.birthday?.month else { return false }
            return contactMonth == monthNumber
        }
    }

    // MARK: - Widget data

    func updateWidgetData() {
        // Next upcoming birthday
        let sorted = contactsWithBirthday.sorted {
            ($0.daysToBirthday ?? Int.max) < ($1.daysToBirthday ?? Int.max)
        }

        let next = sorted.first
        let nextName = next?.name
        let daysToNext = next?.daysToBirthday

        let countThisMonth = birthdaysThisMonthCount

        let data = BirthdayWidgetData(
            nextName: nextName,
            daysToNext: daysToNext,
            upcomingThisMonth: countThisMonth,
            rememberedCount: rememberedBirthdaysCount   // 👈 NEW
        )

        // MUST match your App Group ID on both app + widget targets
        let defaults = UserDefaults(suiteName: "group.com.archit.BirthdayPal")
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: "BirthdayWidgetData")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

}
