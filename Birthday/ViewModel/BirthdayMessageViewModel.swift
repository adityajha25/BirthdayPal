//  BirthdayMessageViewModel.swift

import Foundation
import Contacts
import Combine

final class BirthdayMessageViewModel: ObservableObject {
    @Published var todaysBirthdayContacts: [CNContact] = []
    /// Parallel to `todaysBirthdayContacts`; populated when starting from app `Contact` models.
    @Published private(set) var contactThumbnailData: [Data?] = []
    @Published private(set) var currentIndex: Int = 0
    @Published var showTemplatePicker: Bool = false
    @Published var showComposer: Bool = false
    @Published var composerRecipients: [String] = []
    @Published var composerBody: String = ""
    @Published var lastError: String?
    private let llmService = BirthdayLLMService()
    @Published var isGenerating: Bool = false
    /// Soft notice after generation (guardrail, fallback, etc.).
    @Published var generationNotice: String?
    @Published private(set) var lastGenerationSource: BirthdayLLMSource = .templates

    func startBirthdayFlow(with contacts: [CNContact], thumbnailData: [Data?]? = nil) {
        guard !contacts.isEmpty else {
            lastError = "No contact selected"
            return
        }

        todaysBirthdayContacts = contacts
        if let thumbnailData, thumbnailData.count == contacts.count {
            contactThumbnailData = thumbnailData
        } else {
            contactThumbnailData = contacts.map { Self.thumbnailData(from: $0) }
        }
        currentIndex = 0
        presentTemplateForCurrentContact()
    }

    func thumbnailData(for index: Int) -> Data? {
        guard contactThumbnailData.indices.contains(index) else { return nil }
        return contactThumbnailData[index]
    }

    private static func thumbnailData(from contact: CNContact) -> Data? {
        if let data = contact.thumbnailImageData, !data.isEmpty {
            return data
        }
        if let data = contact.imageData, !data.isEmpty {
            return data
        }
        return nil
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
        tone: MessageTone?,
        name: String,
        age: Int?,
        userHint: String?,
        previousMessageToAvoid: String? = nil
    ) async -> String {
        let outcome = await llmService.generateMessage(
            tone: tone,
            name: name,
            ageOrYear: age,
            userHint: userHint,
            previousMessageToAvoid: previousMessageToAvoid
        )
        await MainActor.run {
            generationNotice = outcome.notice
            lastGenerationSource = outcome.source
        }
        return outcome.text
    }

    func composerFinished() {
        showComposer = false
        advanceToNextContact()
    }

    private func advanceToNextContact() {
        currentIndex += 1
        presentTemplateForCurrentContact()
    }
}
