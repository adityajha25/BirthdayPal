//  MessageTemplatePickerView.swift

import SwiftUI
import Contacts
import FoundationModels   // used only to detect LLM availability

struct MessageTemplatePickerView: View {
    @ObservedObject var messageVM: BirthdayMessageViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedTone: MessageTone?
    @State private var editableMessage: String = ""
    @State private var showEditor: Bool = false
    @State private var userHint: String = ""      // one-liner input
    @State private var llmReady: Bool = false     // track if LLM is available

    // for "Rewrite" support — remember what we used the first time
    @State private var lastTone: MessageTone?
    @State private var lastName: String = ""
    @State private var lastAge: Int? = nil
    @State private var lastHint: String? = nil
    @State private var isRewriting: Bool = false

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
                // Clean blue background
                Color(red: 0.08, green: 0.12, blue: 0.28)
                    .ignoresSafeArea()

                if !showEditor {
                    // Template Selection View
                    ScrollView {
                        VStack(spacing: 24) {
                            if let contact = currentContact {
                                // Header
                                VStack(spacing: 12) {
                                    Text("🎉")
                                        .font(.system(size: 60))
                                    Text("Send Birthday Message")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("to \(displayName(for: contact))")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.top, 40)

                                // One-liner hint field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Add a note (optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    // Use iOS 17 multiline TextField so it wraps naturally
                                    if #available(iOS 17.0, *) {
                                        TextField("e.g. mention our trip, keep it short + funny",
                                                  text: $userHint,
                                                  axis: .vertical)
                                            .lineLimit(1...3)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                                    )
                                            )
                                            .foregroundColor(.white)
                                    } else {
                                        TextField("e.g. mention our trip, keep it short + funny",
                                                  text: $userHint)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                                    )
                                            )
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 20)

                                // Template / Tone options
                                VStack(spacing: 16) {
                                    Text("Choose a message style:")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))

                                    if messageVM.isGenerating {
                                        VStack(spacing: 12) {
                                            ProgressView()
                                                .tint(.cyan)
                                            Text("Generating…")
                                                .foregroundColor(.white.opacity(0.8))
                                                .font(.subheadline)
                                        }
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
                                                            .foregroundColor(.white.opacity(0.4))
                                                            .font(.caption)
                                                    }

                                                    // Only show static preview if LLM is NOT ready
                                                    if !llmReady {
                                                        Text(messagePreview(for: tone, contact: contact))
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.6))
                                                            .lineLimit(2)
                                                    }
                                                }
                                                .padding(16)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                        )
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                Button("Cancel") {
                                    dismiss()
                                }
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.bottom, 20)
                                .padding(.top, 12)
                            } else {
                                Text("No contact selected")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                } else {
                    // Message Editor View
                    VStack(spacing: 20) {
                        // Header
                        HStack(spacing: 12) {
                            Button("Back") {
                                showEditor = false
                            }
                            .foregroundColor(.cyan)

                            Spacer()

                            Text("Edit Message")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            // REWRITE button
                            if isRewriting {
                                ProgressView()
                                    .tint(.cyan)
                            } else {
                                Button("Rewrite") {
                                    Task { await rewriteMessage() }
                                }
                                .foregroundColor(.cyan)
                            }

                            Button("Send") {
                                sendEditedMessage()
                            }
                            .foregroundColor(.cyan)
                            .bold()
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // Text Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview:")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)

                            TextEditor(text: $editableMessage)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal)
                        }

                        Text("Edit the message before sending")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        // Check LLM availability when this view appears
        .task { await updateLLMReadyFlag() }
    }

    // MARK: - Async LLM hook

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
            // Store for "Rewrite"
            lastTone = tone
            lastName = name
            lastAge = age
            lastHint = effectiveHint

            editableMessage = body
            messageVM.isGenerating = false
            showEditor = true
        }
    }

    // MARK: - Rewrite

    private func rewriteMessage() async {
        guard let tone = lastTone else { return }

        await MainActor.run { isRewriting = true }

        // Ask for a different wording than the current message.
        // We piggyback on your existing hint and append a rewrite instruction.
        let baseHint = (lastHint ?? userHint).trimmingCharacters(in: .whitespacesAndNewlines)
        let rewriteNudge = baseHint.isEmpty
            ? "Please give a different wording than the previous one."
            : "\(baseHint) Also generate a different wording than this: '\(editableMessage)'."

        let newBody = await messageVM.generateMessageText(
            tone: tone,
            name: lastName,
            age: lastAge,
            userHint: rewriteNudge
        )

        await MainActor.run {
            editableMessage = newBody
            isRewriting = false
        }
    }

    // MARK: - LLM availability check

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

    // MARK: - Helpers for the view

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
