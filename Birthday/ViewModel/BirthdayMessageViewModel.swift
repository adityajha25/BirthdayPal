import SwiftUI
import Contacts
import Foundation
import Combine

enum MessageTone: String, CaseIterable, Identifiable {
    case formal, casual, funny, romantic
    var id: String { rawValue }
}

// Message Template Picker View
struct MessageTemplatePickerView: View {
    @ObservedObject var messageVM: BirthdayMessageViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTone: MessageTone?
    @State private var editableMessage: String = ""
    @State private var showEditor: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !showEditor {
                    // Template Selection View
                    VStack(spacing: 20) {
                        if messageVM.todaysBirthdayContacts.isEmpty {
                            Text("No contact selected")
                                .foregroundColor(.gray)
                        } else {
                            let contact = messageVM.todaysBirthdayContacts[messageVM.currentIndex]
                            
                            // Header
                            VStack(spacing: 8) {
                                Text("🎉")
                                    .font(.system(size: 60))
                                Text("Send Birthday Message")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("to \(displayName(for: contact))")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 40)
                            
                            Spacer()
                            
                            // Template Options
                            VStack(spacing: 16) {
                                Text("Choose a message style:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                ForEach(MessageTone.allCases) { tone in
                                    Button(action: {
                                        selectedTone = tone
                                        editableMessage = messagePreview(for: tone, contact: contact)
                                        showEditor = true
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(tone.rawValue.capitalized)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text(messagePreview(for: tone, contact: contact))
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(white: 0.15))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    // Message Editor View
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Button("Back") {
                                showEditor = false
                            }
                            .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("Edit Message")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Send") {
                                sendEditedMessage()
                            }
                            .foregroundColor(.blue)
                            .bold()
                        }
                        .padding()
                        
                        // Text Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            TextEditor(text: $editableMessage)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color(white: 0.15))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal)
                        }
                        
                        Text("Edit the message before sending")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func sendEditedMessage() {
        guard let contact = messageVM.todaysBirthdayContacts.first else { return }
        
        // Get phone number
        guard let rawPhone = contact.phoneNumbers.first?.value.stringValue else {
            messageVM.lastError = "No phone number for \(displayName(for: contact))."
            return
        }
        let phone = rawPhone.filter(\.isNumber)
        guard !phone.isEmpty else {
            messageVM.lastError = "No valid phone for \(displayName(for: contact))."
            return
        }
        
        // Set the edited message
        messageVM.composerRecipients = [phone]
        messageVM.composerBody = editableMessage
        
        messageVM.showTemplatePicker = false
        messageVM.showComposer = true
        
        dismiss()
    }

    private func displayName(for contact: CNContact) -> String {
        if !contact.givenName.isEmpty {
            return contact.givenName
        } else if !contact.familyName.isEmpty {
            return contact.familyName
        } else {
            return "there"
        }
    }
    
    private func messagePreview(for tone: MessageTone, contact: CNContact) -> String {
        let name = displayName(for: contact)
        let age = calculateAge(from: contact.birthday)
        return MessageTemplates.make(tone: tone, name: name, age: age)
    }
    
    private func calculateAge(from birthday: DateComponents?) -> Int? {
        guard let birthday = birthday,
              let dob = Calendar.current.date(from: birthday) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}
// Takes in tone, name, optional age and returns a message.
struct MessageTemplates {
    static func make(tone: MessageTone, name: String, age: Int?) -> String {
        switch tone {
        case .formal:
            return "Happy birthday, \(name). Wishing you a wonderful year ahead."
        case .casual:
            if let age {
                return "Happy birthday, \(name)! You're now \(age). Hope it's a great one 🎉"
            } else {
                return "Happy birthday, \(name)! Hope it's a great one 🎉"
            }
        case .funny:
            return "HBD \(name)! Another lap around the sun — level \(age ?? 0) unlocked 🥳"
        case .romantic:
            return "Happy birthday, \(name) ❤️ So grateful for you—hope today is perfect."
        }
    }
}
final class BirthdayMessageViewModel: ObservableObject {
    // contacts for messaging
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

    // entry point - accepts any contact
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

    private static func age(from comps: DateComponents?) -> Int? {
        guard let comps,
              let dob = Calendar.current.date(from: comps) else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}
