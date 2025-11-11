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

    // pretend you already loaded contacts somewhere else
    let allContacts: [CNContact]

    var body: some View {
        VStack(spacing: 16) {
            // Display message count
            VStack(spacing: 8) {
                Text("🎉")
                    .font(.system(size: 40))
                Text("You've sent \(messageCounter.totalMessagesSent) birthday messages!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Button("Send birthday messages for today") {
                vm.startBirthdayFlow(with: allContacts)
            }
            .buttonStyle(.borderedProminent)

            if let err = vm.lastError {
                Text(err)
                    .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $vm.showTemplatePicker) {
            // template picker sheet
            VStack(spacing: 14) {
                Text("Choose a template")
                    .font(.headline)

                ForEach(MessageTone.allCases) { tone in
                    Button(tone.rawValue.capitalized) {
                        vm.userSelectedTemplate(tone)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Cancel") {
                    // if user cancels, just go to next contact
                    vm.composerFinished()
                }
                .foregroundColor(.red)
                .padding(.top)
            }
            .padding()
        }
        .sheet(isPresented: $vm.showComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposerView(
                    recipients: vm.composerRecipients,
                    body: vm.composerBody
                ) { result in
                    // Increment counter only when message is actually sent
                    if result == .sent {
                        messageCounter.incrementMessageCount()
                    }
                    
                    // this is called when user sends/cancels
                    vm.composerFinished()
                }
            } else {
                Text("This device can't send Messages.")
                    .padding()
            }
        }
    }
}

/// Tracks the total number of birthday messages sent by the user
/// Data persists across app launches using UserDefaults
class MessageCounter: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Total number of birthday messages sent (persisted)
    @Published var totalMessagesSent: Int {
        didSet {
            saveToStorage()
        }
    }
    
    // MARK: - Storage Key
    
    private let storageKey = "totalBirthdayMessagesSent"
    
    // MARK: - Initialization
    
    init() {
        // Load saved count from UserDefaults
        self.totalMessagesSent = UserDefaults.standard.integer(forKey: storageKey)
    }
    
    // MARK: - Public Methods
    
    /// Call this method each time a birthday message is sent
    func incrementMessageCount() {
        totalMessagesSent += 1
    }
    
    /// Reset the counter to zero
    func resetCount() {
        totalMessagesSent = 0
    }
        
    private func saveToStorage() {
        UserDefaults.standard.set(totalMessagesSent, forKey: storageKey)
    }
}
