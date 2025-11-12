//  MessageTemplatePickerView.swift

import SwiftUI
import Contacts
import FoundationModels

struct MessageTemplatePickerView: View {
    @ObservedObject var messageVM: BirthdayMessageViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedTone: MessageTone?
    @State private var editableMessage: String = ""
    @State private var showEditor: Bool = false
    @State private var userHint: String = ""
    @State private var llmReady: Bool = false

    // current contact helper
    private var currentContact: CNContact? {
        guard messageVM.todaysBirthdayContacts.indices.contains(messageVM.currentIndex) else {
            return nil
        }
        return messageVM.todaysBirthdayContacts[messageVM.currentIndex]
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if !showEditor {
                    VStack(spacing: 20) {
                        if let contact = currentContact {
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

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add a note (optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                ZStack(alignment: .topLeading) {
                                    if userHint.isEmpty {
                                        Text("e.g. mention our trip, keep it short + funny")
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 12)
                                            .allowsHitTesting(false)
                                    }

                                    TextEditor(text: $userHint)
                                        .frame(minHeight: 60, maxHeight: 100)
                                        .padding(8)
                                        .background(Color(white: 0.15))
                                        .cornerRadius(10)
                                        .scrollContentBackground(.hidden)
                                        .foregroundColor(.white)
                                        .font(.body)
                                }
                            }
                            .padding(.horizontal)

                            VStack(spacing: 16) {
                                Text("Choose a message style:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if messageVM.isGenerating {
                                    ProgressView("Generating…")
                                        .foregroundColor(.white)
                                        .padding()
                                } else {
                                    ForEach(MessageTone.allCases) { tone in
                                        Button(action: {
                                            selectedTone = tone
                                            Task {
                                                await generateMessageForTone(tone, contact: contact)
                                            }
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

                                                // Only show static preview if LLM is NOT ready
                                                if !llmReady {
                                                    Text(messagePreview(for: tone, contact: contact))
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                        .lineLimit(2)
                                                }
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color(white: 0.15))
                                            .cornerRadius(12)
                                        }
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
                        } else {
                            Text("No contact selected")
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
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
        .task {
            await updateLLMReadyFlag()
        }
    }

    private func generateMessageForTone(_ tone: MessageTone, contact: CNContact) async {
        await MainActor.run { messageVM.isGenerating = true }

        let name = displayName(for: contact)
        let age = calculateAge(from: contact.birthday)
        let hint = userHint.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveHint = hint.isEmpty ? nil : hint

        let body = await messageVM.generateMessageText(
            tone: tone,
            name: name,
            age: age,
            userHint: effectiveHint
        )

        await MainActor.run {
            editableMessage = body
            messageVM.isGenerating = false
            showEditor = true
        }
    }

    private func updateLLMReadyFlag() async {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                llmReady = true
            case .unavailable:
                llmReady = false
            @unknown default:
                llmReady = false
            }
        } else {
            llmReady = false
        }
    }


    private func sendEditedMessage() {
        guard let contact = currentContact else { return }

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
        guard
            let birthday,
            birthday.year != nil,
            let dob = Calendar.current.date(from: birthday)
        else {
            return nil
        }

        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}
