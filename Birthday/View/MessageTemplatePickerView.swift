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
    @FocusState private var isNoteFieldFocused: Bool

    private var currentContact: CNContact? {
        guard messageVM.todaysBirthdayContacts.indices.contains(messageVM.currentIndex) else {
            return nil
        }
        return messageVM.todaysBirthdayContacts[messageVM.currentIndex]
    }

    private var canUndo: Bool { messageHistory.count > 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                if !showEditor {
                    promptAndStyleScreen
                } else {
                    messageEditorScreen
                }
            }
            .toolbar(showEditor ? .visible : .hidden, for: .navigationBar)
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
                    let name = displayName(for: contact)
                    VStack(spacing: 12) {
                        ContactPhotoView(
                            name: name,
                            thumbnailData: messageVM.thumbnailData(for: messageVM.currentIndex),
                            size: 80
                        )
                        Text(name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.text)
                        Text("Send Birthday Message")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.text)
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Add a note (optional)", systemImage: "pencil.line")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.text.opacity(0.7))

                        TextField("", text: $userHint)
                            .focused($isNoteFieldFocused)
                            .submitLabel(.done)
                            .onSubmit { isNoteFieldFocused = false }
                            .padding(12)
                            .liquidGlassCard(cornerRadius: LiquidGlass.fieldCornerRadius)
                            .foregroundColor(AppTheme.text)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Message style (optional)", systemImage: "paintbrush.pointed.fill")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.text.opacity(0.7))

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

                    VStack(spacing: 12) {
                        if messageVM.isGenerating {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(AppTheme.accent)
                                Text("Generating…")
                                    .foregroundColor(AppTheme.text.opacity(0.8))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 8)
                        } else {
                            Button {
                                Task {
                                    await generateMessage(tone: selectedTone, contact: contact)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.title3)
                                    Text("Generate")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .primaryGlassButton()
                            .tint(.blue)

                            if !llmReady {
                                Text(messagePreview(for: selectedTone, contact: contact))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.text.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .secondaryGlassButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 4)
                } else {
                    Text("No contact selected")
                        .foregroundColor(AppTheme.text.opacity(0.6))
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded { isNoteFieldFocused = false })
    }

    @ViewBuilder
    private func styleCard(for tone: MessageTone) -> some View {
        let isSelected = selectedTone == tone
        let card = Button {
            selectedTone = isSelected ? nil : tone
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: tone.systemImage)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.white : AppTheme.accent)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? Color.white : AppTheme.text.opacity(0.35))
                }
                Text(tone.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.white : AppTheme.text)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        }
        .browseGlassButtonStyle(isProminent: isSelected)
        .accessibilityLabel(tone.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        if isSelected {
            card.tint(AppTheme.accent)
        } else {
            card
        }
    }

    // MARK: - Editor

    private var messageEditorScreen: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.text.opacity(0.7))
                    .padding(.horizontal)

                ZStack(alignment: .bottom) {
                    TextEditor(text: $editableMessage)
                        .frame(minHeight: 150)
                        .padding(12)
                        .liquidGlassCard(cornerRadius: LiquidGlass.fieldCornerRadius)
                        .foregroundColor(AppTheme.text)
                        .font(.body)
                        .scrollContentBackground(.hidden)

                    if copiedConfirmation {
                        Label("Copied", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(AppTheme.surface.opacity(0.92))
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.text.opacity(0.2), lineWidth: 1)
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

            generationSourceIndicator

            Spacer()

            Button {
                sendEditedMessage()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.title3)
                    Text("Send on iMessage")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .primaryGlassButton()
            .tint(.blue)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .largeNavigationTitle("Edit Message")
        .liquidGlassBackToolbar { showEditor = false }
        .animation(.easeInOut(duration: 0.2), value: copiedConfirmation)
    }

    private var generationSourceIndicator: some View {
        HStack(spacing: 8) {
            if messageVM.lastGenerationSource.showsOnlineIndicator {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            Text(messageVM.lastGenerationSource.displayName)
                .font(.caption)
                .foregroundColor(AppTheme.text.opacity(0.6))
        }
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
                        .tint(AppTheme.accent)
                        .frame(height: 22)
                } else {
                    Image(systemName: systemImage)
                        .font(.title3)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .secondaryGlassButton()
        .tint(AppTheme.accent)
        .disabled(!enabled || isBusy)
        .accessibilityLabel(title)
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
        // Order matches generation: Apple Foundation Models → Gemma (needs network) → templates.
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                llmReady = true
                return
            }
        }
        var canUseGemma = false
        if OpenRouterConfig.isConfigured {
            canUseGemma = await NetworkStatus.isOnline()
        }
        await MainActor.run { llmReady = canUseGemma }
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
