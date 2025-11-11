import SwiftUI
import Contacts
import Foundation
import Combine

enum MessageTone: String, CaseIterable, Identifiable {
    case formal, casual, funny, romantic
    var id: String { rawValue }
}

// Streamlined Message Composer View with AI-First Approach
@available(iOS 18.0, *)
struct MessageTemplatePickerView: View {
    @ObservedObject var messageVM: BirthdayMessageViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTone: MessageTone = .casual
    @State private var generatedMessage: String = ""
    @State private var isGenerating: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if messageVM.todaysBirthdayContacts.isEmpty {
                        Text("No contact selected")
                            .foregroundColor(.gray)
                    } else {
                        let contact = messageVM.todaysBirthdayContacts[messageVM.currentIndex]
                        
                        // Compact Header
                        VStack(spacing: 12) {
                            Text("🎉")
                                .font(.system(size: 50))
                            Text("Birthday message for \(displayName(for: contact))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Tone Selector (Horizontal Pills)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Style")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(MessageTone.allCases) { tone in
                                        Button(action: {
                                            selectedTone = tone
                                            generateMessageWithAI(for: contact, tone: tone)
                                        }) {
                                            Text(tone.rawValue.capitalized)
                                                .font(.subheadline)
                                                .fontWeight(selectedTone == tone ? .semibold : .regular)
                                                .foregroundColor(selectedTone == tone ? .black : .white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(selectedTone == tone ? Color.white : Color(white: 0.2))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // AI-Generated Message Editor
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                    Text("AI-Generated Message")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.blue)
                                
                                Spacer()
                                
                                if !isGenerating && !generatedMessage.isEmpty {
                                    Button(action: {
                                        generateMessageWithAI(for: contact, tone: selectedTone)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Regenerate")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            if isGenerating {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Crafting your message...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(white: 0.15))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            } else {
                                WritingToolsTextEditor(text: $generatedMessage)
                                    .frame(height: 200)
                                    .padding(12)
                                    .background(Color(white: 0.15))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                            }
                            
                            // Direct LLM Access Button
                            if !generatedMessage.isEmpty {
                                Button(action: {
                                    // Trigger Writing Tools directly
                                    triggerWritingTools()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "wand.and.stars")
                                        Text("Refine with Apple Intelligence")
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                
                                Text("💡 Or long-press the text to access Writing Tools manually")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                sendMessage()
                            }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Message")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(generatedMessage.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(generatedMessage.isEmpty)
                            .padding(.horizontal)
                            
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let contact = messageVM.todaysBirthdayContacts.first {
                    generateMessageWithAI(for: contact, tone: selectedTone)
                }
            }
        }
    }
    
    private func triggerWritingTools() {
        // On iOS 18+, we can programmatically trigger Writing Tools
        // by simulating the user action through UITextView's menu
        // The WritingToolsTextEditor should already have writingToolsBehavior = .complete
        
        // Show an alert with instructions since we can't fully automate the Writing Tools popup
        // (Apple doesn't provide a direct API to trigger it programmatically)
        let alert = UIAlertController(
            title: "Apple Intelligence",
            message: "Long-press the message text above, then select 'Writing Tools' → 'Rewrite' to refine your message with Apple Intelligence.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    private func generateMessageWithAI(for contact: CNContact, tone: MessageTone) {
        isGenerating = true
        
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let name = displayName(for: contact)
            let age = calculateAge(from: contact.birthday)
            
            // Generate more varied, AI-like messages
            generatedMessage = generateEnhancedMessage(tone: tone, name: name, age: age)
            isGenerating = false
        }
    }
    
    private func generateEnhancedMessage(tone: MessageTone, name: String, age: Int?) -> String {
        // More varied, personalized templates that feel AI-generated        
        switch tone {
        case .formal:
            let variants = [
                "Wishing you a very happy birthday, \(name). May this year bring you continued success and fulfillment.",
                "Happy birthday, \(name). I hope this special day marks the beginning of a wonderful year ahead for you.",
                "Warmest birthday wishes to you, \(name). May you enjoy this day and the year to come."
            ]
            return variants.randomElement() ?? variants[0]
            
        case .casual:
            if let age = age {
                let variants = [
                    "Happy birthday, \(name)! \(age) looks good on you 🎉 Hope you have an amazing day!",
                    "Hey \(name)! Happy \(age)th birthday! 🎂 Hope it's filled with good vibes and great memories!",
                    "Happy birthday! Can't believe you're \(age) already, \(name)! Have the best day 🥳"
                ]
                return variants.randomElement() ?? variants[0]
            } else {
                let variants = [
                    "Happy birthday, \(name)! 🎉 Hope your day is as awesome as you are!",
                    "Wishing you the happiest of birthdays, \(name)! 🎂 Enjoy your special day!",
                    "Hey \(name)! Happy birthday! 🥳 Hope you have a fantastic celebration!"
                ]
                return variants.randomElement() ?? variants[0]
            }
            
        case .funny:
            let ageNum = age ?? 25
            let variants = [
                "Happy birthday, \(name)! You're now level \(ageNum) 🎮 New achievements unlocked! 🥳",
                "Another year wiser (or just older)! Happy \(ageNum)th birthday, \(name)! 😄🎉",
                "Congrats on surviving another lap around the sun, \(name)! Level \(ageNum) activated! 🚀🎂"
            ]
            return variants.randomElement() ?? variants[0]
            
        case .romantic:
            let variants = [
                "Happy birthday to my favorite person ❤️ \(name), I'm so grateful for every moment with you. Here's to celebrating you today!",
                "Happy birthday, \(name) 💕 You make every day brighter. Hope today is as wonderful as you are!",
                "Wishing the happiest of birthdays to you, \(name) ❤️ So lucky to have you in my life. Let's make today special!"
            ]
            return variants.randomElement() ?? variants[0]
        }
    }
    
    private func sendMessage() {
        guard let contact = messageVM.todaysBirthdayContacts.first else { return }
        
        guard let rawPhone = contact.phoneNumbers.first?.value.stringValue else {
            messageVM.lastError = "No phone number for \(displayName(for: contact))."
            return
        }
        let phone = rawPhone.filter(\.isNumber)
        guard !phone.isEmpty else {
            messageVM.lastError = "No valid phone for \(displayName(for: contact))."
            return
        }
        
        messageVM.composerRecipients = [phone]
        messageVM.composerBody = generatedMessage
        
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
