//
//  SettingsView.swift
//  Birthday
//

import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @ObservedObject var contactsVM: ContactViewModel
    @ObservedObject private var settings = AppSettings.shared

    @State private var showShareSheet = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var initialPingDraft = ""
    @FocusState private var isInitialPingFocused: Bool

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.12, blue: 0.28)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    notificationsSection
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
        .toolbarBackground(Color(red: 0.08, green: 0.12, blue: 0.28), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInitialPingFocused = false
                    commitInitialPingDraft(normalize: true)
                }
                .foregroundStyle(.cyan)
            }
        }
        .task {
            await refreshNotificationStatus()
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("Notifications, support, and more")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Sections

    private var notificationsSection: some View {
        settingsSection(title: "Notifications") {
            Toggle(isOn: $settings.notificationsEnabled) {
                settingsLabel(
                    icon: "bell.fill",
                    title: "Birthday reminders",
                    subtitle: notificationStatusSubtitle
                )
            }
            .tint(.cyan)

            Divider().overlay(Color.white.opacity(0.12))

            DatePicker(
                "Reminder time",
                selection: Binding(
                    get: { settings.notificationTime },
                    set: { settings.notificationTime = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .foregroundStyle(.white)
            .tint(.cyan)
            .colorScheme(.dark)
            .disabled(!settings.notificationsEnabled)
            .opacity(settings.notificationsEnabled ? 1 : 0.45)

            Divider().overlay(Color.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 12) {
                settingsLabel(
                    icon: "bell.badge",
                    title: "Initial ping",
                    subtitle: initialPingSubtitle
                )

                HStack(spacing: 10) {
                    TextField(
                        "",
                        text: initialPingDraftBinding,
                        prompt: Text("Off").foregroundStyle(.white.opacity(0.35))
                    )
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .focused($isInitialPingFocused)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(minWidth: 52, maxWidth: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.cyan.opacity(isInitialPingFocused ? 0.55 : 0.18), lineWidth: 1)
                    )
                    .accessibilityLabel("Days before birthday")

                    Text(settings.initialPingDays == 1 ? "day before" : "days before")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Stepper(
                        "",
                        value: $settings.initialPingDays,
                        in: 0...AppSettings.initialPingDaysMax
                    )
                    .labelsHidden()
                    .tint(.cyan)
                    .fixedSize()
                    .accessibilityLabel("Initial ping days")
                }
            }
            .colorScheme(.dark)
            .disabled(!settings.notificationsEnabled)
            .opacity(settings.notificationsEnabled ? 1 : 0.45)

            Divider().overlay(Color.white.opacity(0.12))

            Button {
                openSystemSettings()
            } label: {
                settingsRow(
                    icon: "gear",
                    title: "System notification settings",
                    subtitle: "Open iOS Settings"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var displaySection: some View {
        settingsSection(title: "Display") {
            Toggle(isOn: $settings.showAgeTurning) {
                settingsLabel(
                    icon: "cake",
                    title: "Show age turning",
                    subtitle: "Only when birth year is available"
                )
            }
            .tint(.cyan)

            Divider().overlay(Color.white.opacity(0.12))

            Button {
                contactsVM.loadContacts(force: true)
                contactsVM.loadMissingBirthdayContactsIfNeeded(force: true)
            } label: {
                settingsRow(
                    icon: "arrow.clockwise",
                    title: "Refresh contacts",
                    subtitle: "Reload birthdays from Contacts"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var supportSection: some View {
        settingsSection(title: "Support & Sharing") {
            Button {
                openURL(AppSettings.writeReviewURL)
            } label: {
                settingsRow(
                    icon: "star.fill",
                    title: "Rate on the App Store",
                    subtitle: "Leave a review"
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(Color.white.opacity(0.12))

            Button {
                showShareSheet = true
            } label: {
                settingsRow(
                    icon: "square.and.arrow.up",
                    title: "Send to a friend",
                    subtitle: "Share the App Store link"
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(Color.white.opacity(0.12))

            Button {
                openMail(
                    to: AppSettings.supportEmail,
                    subject: "BirthdayPal Support",
                    body: "Hi BirthdayPal team,\n\n"
                )
            } label: {
                settingsRow(
                    icon: "envelope.fill",
                    title: "Contact us",
                    subtitle: AppSettings.supportEmail
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(Color.white.opacity(0.12))

            Button {
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
            } label: {
                settingsRow(
                    icon: "exclamationmark.bubble.fill",
                    title: "Report a bug",
                    subtitle: "Email with device details filled in"
                )
            }
            .buttonStyle(.plain)
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

            Divider().overlay(Color.white.opacity(0.12))

            HStack {
                settingsLabel(
                    icon: "lock.shield.fill",
                    title: "Privacy",
                    subtitle: "Birthdays stay on your device"
                )
                Spacer()
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
                .foregroundStyle(.white.opacity(0.55))
                .padding(.leading, 4)

            GlassCard(intensity: .strong) {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(20)
            }
        }
    }

    private func settingsLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            settingsLabel(icon: icon, title: title, subtitle: subtitle)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.35))
        }
        .contentShape(Rectangle())
    }

    private var notificationStatusSubtitle: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Always reminds on the birthday"
        case .denied:
            return "Permission denied — enable in Settings"
        case .notDetermined:
            return "We’ll ask for permission when needed"
        @unknown default:
            return "Always reminds on the birthday"
        }
    }

    private var initialPingSubtitle: String {
        switch settings.initialPingDays {
        case 0:
            return "Empty or 0 is Off — day-of still fires"
        case 1:
            return "Also notify 1 day before"
        default:
            return "Also notify \(settings.initialPingDays) days before"
        }
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

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
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
