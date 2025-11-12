//
//  BirthdaySenderView.swift
//  Birthday
//
//  Created by Archit Lakhani on 10/30/25.
//

import SwiftUI
import Contacts
import Combine
import MessageUI

struct BirthdaySenderView: View {
    @StateObject private var vm = BirthdayMessageViewModel()
    @StateObject private var messageCounter = MessageCounter()

    let allContacts: [CNContact]

    var body: some View {
        VStack(spacing: 16) {
            // ... existing code ...
        }
        .sheet(isPresented: $vm.showTemplatePicker) {
            if #available(iOS 18.0, *) {
                MessageTemplatePickerView(
                    messageVM: vm,
                    messageCounter: messageCounter // Pass the counter
                )
            }
        }
        .sheet(isPresented: $vm.showComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposerView(
                    recipients: vm.composerRecipients,
                    body: vm.composerBody
                ) { result in
                    if result == .sent,
                       let contact = vm.todaysBirthdayContacts[safe: vm.currentIndex] {
                        messageCounter.recordMessage(
                            to: contact.identifier,
                            message: vm.composerBody,
                            contactName: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                        )
                    }
                    vm.composerFinished()
                }
            } else {
                Text("This device can't send Messages.")
                    .padding()
            }
        }
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


/// Tracks birthday messages sent to contacts
/// Data persists across app launches using UserDefaults
class MessageCounter: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Total number of birthday messages sent (persisted)
    @Published var totalMessagesSent: Int {
        didSet {
            saveToStorage()
        }
    }
    
    /// Dictionary mapping contact identifiers to their message history
    @Published var messageHistory: [String: [MessageRecord]] {
        didSet {
            saveToStorage()
        }
    }
    
    // MARK: - Storage Keys
    
    private let totalCountKey = "totalBirthdayMessagesSent"
    private let messageHistoryKey = "birthdayMessageHistory"
    
    // MARK: - Initialization
    
    init() {
        // Load saved count from UserDefaults
        self.totalMessagesSent = UserDefaults.standard.integer(forKey: totalCountKey)
        
        // Load message history from UserDefaults
        if let data = UserDefaults.standard.data(forKey: messageHistoryKey),
           let decoded = try? JSONDecoder().decode([String: [MessageRecord]].self, from: data) {
            self.messageHistory = decoded
        } else {
            self.messageHistory = [:]
        }
    }
    
    // MARK: - Public Methods
    
    /// Records a message sent to a specific contact
    /// - Parameters:
    ///   - contactIdentifier: Unique identifier for the contact (CNContact.identifier)
    ///   - message: The message text that was sent
    ///   - contactName: Optional name of the contact for easier reference
    func recordMessage(to contactIdentifier: String, message: String, contactName: String? = nil) {
        let record = MessageRecord(
            message: message,
            dateSent: Date(),
            contactName: contactName
        )
        
        if messageHistory[contactIdentifier] != nil {
            messageHistory[contactIdentifier]?.append(record)
        } else {
            messageHistory[contactIdentifier] = [record]
        }
        
        totalMessagesSent += 1
    }
    
    /// Retrieves all messages sent to a specific contact
    /// - Parameter contactIdentifier: Unique identifier for the contact
    /// - Returns: Array of message records, sorted by date (newest first)
    func getMessages(for contactIdentifier: String) -> [MessageRecord] {
        return messageHistory[contactIdentifier]?.sorted(by: { $0.dateSent > $1.dateSent }) ?? []
    }
    
    /// Gets the most recent message sent to a contact
    /// - Parameter contactIdentifier: Unique identifier for the contact
    /// - Returns: The most recent message record, or nil if no messages exist
    func getLastMessage(for contactIdentifier: String) -> MessageRecord? {
        return messageHistory[contactIdentifier]?.max(by: { $0.dateSent < $1.dateSent })
    }
    
    /// Reset the counter to zero and clear all message history
    func resetAll() {
        totalMessagesSent = 0
        messageHistory = [:]
    }
    
    /// Reset messages for a specific contact
    /// - Parameter contactIdentifier: Unique identifier for the contact
    func resetMessages(for contactIdentifier: String) {
        if let count = messageHistory[contactIdentifier]?.count {
            totalMessagesSent -= count
        }
        messageHistory.removeValue(forKey: contactIdentifier)
    }
    
    // MARK: - Private Methods
    
    private func saveToStorage() {
        UserDefaults.standard.set(totalMessagesSent, forKey: totalCountKey)
        
        if let encoded = try? JSONEncoder().encode(messageHistory) {
            UserDefaults.standard.set(encoded, forKey: messageHistoryKey)
        }
    }
}

// MARK: - Supporting Types

/// Represents a single birthday message sent to a contact
struct MessageRecord: Codable, Identifiable {
    let id: UUID
    let message: String
    let dateSent: Date
    let contactName: String?
    
    init(message: String, dateSent: Date, contactName: String? = nil) {
        self.id = UUID()
        self.message = message
        self.dateSent = dateSent
        self.contactName = contactName
    }
}
