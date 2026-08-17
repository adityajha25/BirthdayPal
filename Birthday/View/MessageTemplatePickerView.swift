//  MessageTemplatePickerView.swift

import SwiftUI
import UIKit
import Contacts
import FoundationModels   // used only to detect LLM availability

struct MessageTemplatePickerView: View {
    @ObservedObject var messageVM: BirthdayMessageViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedTone: MessageTone?
    @State private var editableMessage: String = ""
    @State private var showEditor: Bool = false
    @State private var userHint: String = ""
    @State private var llmReady: Bool = false

    @State private var lastTone: MessageTone?
    @State private var lastName: String = ""
    @State private var lastAge: Int? = nil
    @State private var lastHint: String? = nil
    @State private var isRewriting: Bool = false

    @State private var messageHistory: [String] = []
    @State private var showShareSheet: Bool = false
    @State private var copiedConfirmation: Bool = false
    @State private var copyResetTask: Task<Void, Never>?

    private var currentContact: CNContact? {
        guard messageVM.todaysBirthdayContacts.indices.contains(messageVM.currentIndex) else {
            return nil
        }
        return messageVM.todaysBirthdayContacts[messageVM.currentIndex]
    }

    private var canUndo: Bool { messageHistory.count > 1 }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.12, blue: 0.28)
                    .ignoresSafeArea()

                if !showEditor {
                    promptAndStyleScreen
                } else {
                    messageEditorScreen
                }
            }
            .navigationBarHidden(true)
        }
        .task { await updateLLMReadyFlag() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [editableMessage])
        }
        .alert(
            "Heads up",
            isPresented: Binding(
                get: { messageVM.generationNotice != nil },
                set: { if !$0 { messageVM.generationNotice = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                messageVM.generationNotice = nil
            }
        } message: {
            Text(messageVM.generationNotice ?? "")
        }
        .onDisappear {
            copyResetTask?.cancel()
        }
    }

    // MARK: - Prompt + style

    @ViewBuilder
    private var promptAndStyleScreen: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let contact = currentContact {
                    VStack(spacing: 12) {
                        ContactPhotoView(
                            name: displayName(for: contact),
                            thumbnailData: photoData(for: contact),
                            size: 80
                        )
                        Text("Send Birthday Message")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("to \(displayName(for: contact))")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Add a note (optional)", systemImage: "pencil.line")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        TextField("e.g. mention our trip, keep it short",
                                  text: $userHint,
                                  axis: .vertical)
                            .lineLimit(1...3)
                            .padding(12)
                            .background(glassFieldBackground)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Message style (optional)", systemImage: "paintbrush.pointed.fill")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        Text("Pick a style, or skip it and generate from your note.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        skipStyleCard

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(MessageTone.allCases) { tone in
                                styleCard(for: tone)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if messageVM.isGenerating {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.cyan)
                            Text("Generating…")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                        .padding(.top, 4)
                    } else {
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await generateMessage(tone: selectedTone, contact: contact)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.title3)
                                    Text(generateButtonTitle)
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                            }

                            if selectedTone != nil {
                                Button {
                                    selectedTone = nil
                                    Task {
                                        await generateMessage(tone: nil, contact: contact)
                                    }
                                } label: {
                                    Label("Generate without a style", systemImage: "text.bubble")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.cyan)
                                }
                            }

                            if !llmReady {
                                Text(messagePreview(for: selectedTone, contact: contact))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                    .padding(.top, 8)
                } else {
                    Text("No contact selected")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    private var skipStyleCard: some View {
        Button {
            selectedTone = nil
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No style")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Follow your note only")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: selectedTone == nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedTone == nil ? .cyan : .white.opacity(0.35))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(glassCardBackground(isSelected: selectedTone == nil))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("No style")
        .accessibilityAddTraits(selectedTone == nil ? .isSelected : [])
    }

    private func styleCard(for tone: MessageTone) -> some View {
        let isSelected = selectedTone == tone
        return Button {
            selectedTone = isSelected ? nil : tone
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: tone.systemImage)
                        .font(.title3)
                        .foregroundStyle(.cyan)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .cyan : .white.opacity(0.35))
                }
                Text(tone.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .background(glassCardBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tone.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var generateButtonTitle: String {
        if let selectedTone {
            return "Generate \(selectedTone.displayName) Message"
        }
        return "Generate without a style"
    }

    // MARK: - Editor

    private var messageEditorScreen: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    showEditor = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .foregroundColor(.cyan)

                Spacer()

                Text("Edit Message")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
                    .frame(width: 64)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal)

                ZStack(alignment: .bottom) {
                    TextEditor(text: $editableMessage)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(glassFieldBackground)
                        .foregroundColor(.white)
                        .font(.body)
                        .scrollContentBackground(.hidden)

                    if copiedConfirmation {
                        Label("Copied", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.92))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.bottom, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 10) {
                editorActionButton(
                    title: "Copy",
                    systemImage: "doc.on.doc",
                    enabled: !editableMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    copyMessageToClipboard()
                }

                editorActionButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    enabled: !editableMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    showShareSheet = true
                }

                editorActionButton(
                    title: "Rewrite",
                    systemImage: "arrow.triangle.2.circlepath",
                    isBusy: isRewriting
                ) {
                    Task { await rewriteMessage() }
                }

                editorActionButton(
                    title: "Undo",
                    systemImage: "arrow.uturn.backward",
                    enabled: canUndo && !isRewriting
                ) {
                    undoLastRewrite()
                }
            }
            .padding(.horizontal)

            VStack(spacing: 4) {
                Text("Edit the message before sending")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Text(editorContextCaption)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            Button {
                sendEditedMessage()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.title3)
                    Text("Send via Messages")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: copiedConfirmation)
    }

    private var editorContextCaption: String {
        if let lastTone {
            return "Style: \(lastTone.displayName)"
        }
        return "No style — based on your note"
    }

    private func editorActionButton(
        title: String,
        systemImage: String,
        enabled: Bool = true,
        isBusy: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isBusy {
                    ProgressView()
                        .tint(.cyan)
                        .frame(height: 22)
                } else {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(enabled ? Color.cyan : Color.white.opacity(0.3))
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(enabled ? .white.opacity(0.85) : .white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(glassCardBackground(isSelected: false))
        }
        .buttonStyle(.plain)
        .disabled(!enabled || isBusy)
        .accessibilityLabel(title)
    }

    // MARK: - Glass helpers

    private var glassFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }

    private func glassCardBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(isSelected ? 0.75 : 0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.cyan.opacity(0.75) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
    }

    // MARK: - Generate / rewrite / undo

    private func generateMessage(tone: MessageTone?, contact: CNContact) async {
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
            lastTone = tone
            selectedTone = tone
            lastName = name
            lastAge = age
            lastHint = effectiveHint

            editableMessage = body
            messageHistory = [body]
            messageVM.isGenerating = false
            showEditor = true
        }
    }

    private func rewriteMessage() async {
        await MainActor.run { isRewriting = true }

        // Keep the original prompt/style; pass the old draft only as previousMessageToAvoid.
        let newBody = await messageVM.generateMessageText(
            tone: lastTone,
            name: lastName,
            age: lastAge,
            userHint: lastHint,
            previousMessageToAvoid: editableMessage
        )

        await MainActor.run {
            editableMessage = newBody
            messageHistory.append(newBody)
            isRewriting = false
        }
    }

    private func undoLastRewrite() {
        guard canUndo else { return }
        messageHistory.removeLast()
        editableMessage = messageHistory.last ?? editableMessage
    }

    private func copyMessageToClipboard() {
        UIPasteboard.general.string = editableMessage
        copiedConfirmation = true
        copyResetTask?.cancel()
        copyResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            copiedConfirmation = false
        }
    }

    // MARK: - LLM availability check

    /// True when on-device Apple Intelligence or the OpenRouter edge function can generate.
    private func updateLLMReadyFlag() async {
        if OpenRouterConfig.isConfigured {
            llmReady = true
            return
        }
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

    private func photoData(for contact: CNContact) -> Data? {
        if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
            return contact.thumbnailImageData
        }
        if contact.isKeyAvailable(CNContactImageDataKey) {
            return contact.imageData
        }
        return nil
    }

    private func messagePreview(for tone: MessageTone?, contact: CNContact) -> String {
        let name = displayName(for: contact)
        let age = calculateAge(from: contact.birthday)
        return MessageTemplates.make(tone: tone, name: name, age: age)
    }

    private func calculateAge(from birthday: DateComponents?) -> Int? {
        guard
            let birthday,
            let year = Contact.validBirthYear(birthday.year),
            let month = birthday.month,
            let day = birthday.day
        else {
            return nil
        }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        guard let dob = Calendar.current.date(from: comps) else { return nil }
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year
        return (age ?? 0) > 0 ? age : nil
    }
}
