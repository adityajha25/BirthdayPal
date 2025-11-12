//  BirthdayMessageViewModel.swift

import Foundation
import Contacts
import Combine

final class BirthdayMessageViewModel: ObservableObject {
    @Published var todaysBirthdayContacts: [CNContact] = []
    @Published private(set) var currentIndex: Int = 0
    @Published var showTemplatePicker: Bool = false
    @Published var showComposer: Bool = false
    @Published var composerRecipients: [String] = []
    @Published var composerBody: String = ""
    @Published var lastError: String?
    private let llmService = BirthdayLLMService()
    @Published var isGenerating: Bool = false
    func startBirthdayFlow(with contacts: [CNContact]) {
        guard !contacts.isEmpty else {
            lastError = "No contact selected"
            return
        }

        todaysBirthdayContacts = contacts
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
    func generateMessageText(
        tone: MessageTone,
        name: String,
        age: Int?,
        userHint: String?
    ) async -> String {
        await llmService.generateMessage(
            tone: tone,
            name: name,
            ageOrYear: age,
            userHint: userHint
        )
    }

    func composerFinished() {
        showComposer = false
        advanceToNextContact()
    }

    private func advanceToNextContact() {
        currentIndex += 1
        presentTemplateForCurrentContact()
    }
    

    func displayName(for contact: CNContact) -> String {
        if !contact.givenName.isEmpty {
            return contact.givenName
        } else if !contact.familyName.isEmpty {
            return contact.familyName
        } else {
            return "there"
        }
    }

    static func age(from comps: DateComponents?) -> Int? {
        guard let comps,
              let dob = Calendar.current.date(from: comps) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}
