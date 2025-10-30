import SwiftUI
import Contacts
import Foundation
import Combine

enum MessageTone: String, CaseIterable, Identifiable {
    case formal, casual, funny, romantic
    var id: String { rawValue }
}

// Takes in tone, name, optional age and returns a message.
struct MessageTemplates {
    static func make(tone: MessageTone, name: String, age: Int?) -> String {
        switch tone {
        case .formal:
            return "Happy birthday, \(name). Wishing you a wonderful year ahead."
        case .casual:
            if let age {
                return "Happy birthday, \(name)! You're now \(age). Hope it’s a great one 🎉"
            } else {
                return "Happy birthday, \(name)! Hope it’s a great one 🎉"
            }
        case .funny:
            return "HBD \(name)! Another lap around the sun — level \(age ?? 0) unlocked 🥳"
        case .romantic:
            return "Happy birthday, \(name) ❤️ So grateful for you—hope today is perfect."
        }
    }
}

final class BirthdayMessageViewModel: ObservableObject {
    // contacts whose birthday is today
    @Published var todaysBirthdayContacts: [CNContact] = []

    // index of the current person
    @Published private(set) var currentIndex: Int = 0

    // UI flags
    @Published var showTemplatePicker: Bool = false
    @Published var showComposer: Bool = false

    // data for composer
    @Published var composerRecipients: [String] = []
    @Published var composerBody: String = ""

    // errors
    @Published var lastError: String?

    // entry point
    func startBirthdayFlow(with contacts: [CNContact]) {
        let todays = contacts.filter { Self.isBirthdayToday($0.birthday) }

        guard !todays.isEmpty else {
            lastError = "No birthdays today 🎂"
            return
        }

        todaysBirthdayContacts = todays
        currentIndex = 0
        presentTemplateForCurrentContact()
    }

    private func presentTemplateForCurrentContact() {
        guard currentIndex < todaysBirthdayContacts.count else {
            // all done
            showTemplatePicker = false
            showComposer = false
            return
        }
        showTemplatePicker = true
    }

    func userSelectedTemplate(_ tone: MessageTone) {
        let contact = todaysBirthdayContacts[currentIndex]

        // phone
        guard let rawPhone = contact.phoneNumbers.first?.value.stringValue else {
            lastError = "No phone number for \(displayName(for: contact))."
            advanceToNextContact()
            return
        }
        let phone = rawPhone.filter(\.isNumber)
        guard !phone.isEmpty else {
            lastError = "No valid phone for \(displayName(for: contact))."
            advanceToNextContact()
            return
        }

        let name = displayName(for: contact)
        let age = Self.age(from: contact.birthday)

        composerRecipients = [phone]
        composerBody = MessageTemplates.make(tone: tone, name: name, age: age)

        showTemplatePicker = false
        showComposer = true
    }

    func composerFinished() {
        showComposer = false
        advanceToNextContact()
    }

    private func advanceToNextContact() {
        currentIndex += 1
        presentTemplateForCurrentContact()
    }

    // MARK: helpers

    private func displayName(for contact: CNContact) -> String {
        if !contact.givenName.isEmpty {
            return contact.givenName
        } else if !contact.familyName.isEmpty {
            return contact.familyName
        } else {
            return "there"
        }
    }

    private static func isBirthdayToday(_ comps: DateComponents?) -> Bool {
        guard let comps,
              let month = comps.month,
              let day = comps.day else { return false }

        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        return today.month == month && today.day == day
    }

    private static func age(from comps: DateComponents?) -> Int? {
        guard let comps,
              let dob = Calendar.current.date(from: comps) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}
