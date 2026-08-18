//
//  SettingsView.swift
//  Birthday
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var contactsVM: ContactViewModel
    @ObservedObject private var settings = AppSettings.shared

    @State private var showShareSheet = false
    @State private var initialPingDraft = ""
    @State private var showRefreshConfirmation = false
    @State private var refreshConfirmationTask: Task<Void, Never>?
    @FocusState private var isInitialPingFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    notificationsSection
                    messagesSection
                    displaySection
                    supportSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .largeNavigationTitle("Settings")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInitialPingFocused = false
                    commitInitialPingDraft(normalize: true)
                }
                .foregroundStyle(AppTheme.accent)
            }
        }
        .task {
            syncInitialPingDraft(from: settings.initialPingDays)
        }
        .onChange(of: settings.notificationHour) { _, _ in
            rescheduleNotifications()
        }
        .onChange(of: settings.notificationMinute) { _, _ in
            rescheduleNotifications()
        }
        .onChange(of: settings.initialPingDays) { _, days in
            let parsed = Int(initialPingDraft.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            if parsed != days {
                syncInitialPingDraft(from: days)
            }
            rescheduleNotifications()
        }
        .onChange(of: isInitialPingFocused) { _, focused in
            if !focused {
                commitInitialPingDraft(normalize: true)
            }
        }
        .onChange(of: settings.notificationsEnabled) { _, enabled in
            if enabled {
                BirthdayNotificationManager.shared.requestAuthorizationIfNeeded()
                rescheduleNotifications()
            } else {
                BirthdayNotificationManager.shared.clearAllBirthdayNotifications()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - Sections

    private var notificationsSection: some View {
        settingsSection(title: "Notifications") {
            Toggle(isOn: $settings.notificationsEnabled) {
                settingsLabel(icon: "bell.fill", title: "Birthday Reminders")
            }
            .tint(AppTheme.accent)

            Divider().overlay(AppTheme.text.opacity(0.12))

            DatePicker(
                "Reminder Time",
                selection: Binding(
                    get: { settings.notificationTime },
                    set: { settings.notificationTime = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .foregroundStyle(AppTheme.text)
            .tint(AppTheme.accent)
            .disabled(!settings.notificationsEnabled)
            .opacity(settings.notificationsEnabled ? 1 : 0.45)

            Divider().overlay(AppTheme.text.opacity(0.12))

            VStack(alignment: .leading, spacing: 12) {
                settingsLabel(icon: "bell.badge", title: "Initial Ping")

                HStack(spacing: 10) {
                    TextField(
                        "",
                        text: initialPingDraftBinding,
                        prompt: Text("Off").foregroundStyle(AppTheme.text.opacity(0.35))
                    )
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .focused($isInitialPingFocused)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(minWidth: 52, maxWidth: 64)
                    .liquidGlassCard(cornerRadius: 10)
                    .accessibilityLabel("Days Before Birthday")

                    Text(settings.initialPingDays == 1 ? "day before" : "days before")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text.opacity(0.65))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Stepper(
                        "",
                        value: $settings.initialPingDays,
                        in: 0...AppSettings.initialPingDaysMax
                    )
                    .labelsHidden()
                    .tint(AppTheme.accent)
                    .fixedSize()
                    .accessibilityLabel("Initial Ping Days")
                }
            }
            .disabled(!settings.notificationsEnabled)
            .opacity(settings.notificationsEnabled ? 1 : 0.45)

            Divider().overlay(AppTheme.text.opacity(0.12))

            settingsActionButton(icon: "gear", title: "System Notification Settings") {
                openSystemSettings()
            }
        }
    }

    private var messagesSection: some View {
        settingsSection(title: "Messages") {
            Toggle(isOn: $settings.aiAssistanceEnabled) {
                settingsLabel(
                    icon: "sparkles",
                    title: "AI Assistance",
                )
            }
            .tint(AppTheme.accent)
        }
    }

    private var displaySection: some View {
        settingsSection(title: "Display") {
            Toggle(isOn: $settings.showAgeTurning) {
                settingsLabel(icon: "cake", title: "Show Age Turning")
            }
            .tint(AppTheme.accent)

            Divider().overlay(AppTheme.text.opacity(0.12))

            refreshContactsRow
        }
    }

    /// Refresh with visible feedback: a spinner while the fetch runs, then a short "Updated" note.
    private var refreshContactsRow: some View {
        Button {
            refreshContacts()
        } label: {
            HStack(spacing: 12) {
                settingsLabel(
                    icon: "arrow.clockwise",
                    title: "Refresh Contacts",
                    subtitle: showRefreshConfirmation ? "Updated just now" : nil
                )

                Spacer(minLength: 0)

                if contactsVM.isRefreshingContacts {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppTheme.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(contactsVM.isRefreshingContacts)
        .animation(.easeInOut(duration: 0.2), value: contactsVM.isRefreshingContacts)
        .animation(.easeInOut(duration: 0.2), value: showRefreshConfirmation)
        .onChange(of: contactsVM.isRefreshingContacts) { wasRefreshing, isRefreshing in
            guard wasRefreshing, !isRefreshing else { return }
            showRefreshConfirmation = true
            refreshConfirmationTask?.cancel()
            refreshConfirmationTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                showRefreshConfirmation = false
            }
        }
        .onDisappear { refreshConfirmationTask?.cancel() }
    }

    private func refreshContacts() {
        showRefreshConfirmation = false
        refreshConfirmationTask?.cancel()
        contactsVM.refreshAllContacts()
    }

    private var supportSection: some View {
        settingsSection(title: "Support & Sharing") {
            settingsActionButton(icon: "star.fill", title: "Rate on the App Store") {
                openURL(AppSettings.writeReviewURL)
            }

            Divider().overlay(AppTheme.text.opacity(0.12))

            settingsActionButton(icon: "square.and.arrow.up", title: "Send to a Friend") {
                showShareSheet = true
            }

            Divider().overlay(AppTheme.text.opacity(0.12))

            settingsActionButton(
                icon: "envelope.fill",
                title: "Contact Us",
                subtitle: AppSettings.supportEmail
            ) {
                openMail(
                    to: AppSettings.supportEmail,
                    subject: "BirthdayPal Support",
                    body: "Hi BirthdayPal team,\n\n"
                )
            }

            Divider().overlay(AppTheme.text.opacity(0.12))

            settingsActionButton(
                icon: "exclamationmark.bubble.fill",
                title: "Report a bug",
                subtitle: "Email with device details filled in"
            ) {
                openMail(
                    to: AppSettings.supportEmail,
                    subject: "BirthdayPal Bug Report",
                    body: """
                    Hi BirthdayPal team,

                    Bug description:


                    Steps to reproduce:


                    App version: \(settings.appVersion)
                    Device: \(UIDevice.current.model)
                    iOS: \(UIDevice.current.systemVersion)

                    """
                )
            }
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            HStack {
                settingsLabel(
                    icon: "info.circle.fill",
                    title: "Version",
                    subtitle: settings.appVersion
                )
                Spacer()
            }

            Divider().overlay(AppTheme.text.opacity(0.12))

            settingsActionButton(icon: "lock.shield.fill", title: "Privacy") {
                openURL(AppSettings.appStoreURL)
            }
        }
    }

    // MARK: - Building blocks

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.text.opacity(0.55))
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(20)
            .liquidGlassCard(cornerRadius: LiquidGlass.cardCornerRadius)
        }
    }

    private func settingsLabel(icon: String, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.text.opacity(0.6))
                }
            }
        }
    }

    private func settingsActionButton(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                settingsLabel(icon: icon, title: title, subtitle: subtitle)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var initialPingDraftBinding: Binding<String> {
        Binding(
            get: { initialPingDraft },
            set: { commitInitialPingDraft(raw: $0, normalize: false) }
        )
    }

    private func syncInitialPingDraft(from days: Int) {
        initialPingDraft = days == 0 ? "" : String(days)
    }

    /// Parses the days field. Empty or 0 → Off. Negatives and non-integers are rejected; values above the max are clamped.
    private func commitInitialPingDraft(raw: String? = nil, normalize: Bool) {
        let source = raw ?? initialPingDraft
        let digitsOnly = source.filter { $0 >= "0" && $0 <= "9" }

        if digitsOnly.isEmpty {
            initialPingDraft = ""
            if settings.initialPingDays != 0 {
                settings.initialPingDays = 0
            }
            return
        }

        guard let value = Int(digitsOnly) else {
            syncInitialPingDraft(from: settings.initialPingDays)
            return
        }

        let clamped = AppSettings.clampedInitialPingDays(value)
        if settings.initialPingDays != clamped {
            settings.initialPingDays = clamped
        }
        if normalize || clamped != value {
            syncInitialPingDraft(from: clamped)
        } else {
            initialPingDraft = digitsOnly
        }
    }

    private var shareItems: [Any] {
        [
            "Never miss a birthday with BirthdayPal!",
            AppSettings.appStoreURL
        ]
    }

    // MARK: - Actions

    private func rescheduleNotifications() {
        guard settings.notificationsEnabled else { return }
        BirthdayNotificationManager.shared.refreshDailySchedule(
            contacts: contactsVM.contactsWithBirthday
        )
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }

    private func openMail(to email: String, subject: String, body: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        if let url = components.url {
            openURL(url)
        }
    }
}
