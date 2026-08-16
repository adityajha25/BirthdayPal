//
//  SettingsView.swift
//  Birthday
//

import SwiftUI
import UIKit
import UserNotifications

@available(iOS 17.0, *)
struct SettingsView: View {
    @ObservedObject var contactsVM: ContactViewModel
    @ObservedObject private var settings = AppSettings.shared

    @State private var showShareSheet = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

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
        }
        .toolbarBackground(Color(red: 0.08, green: 0.12, blue: 0.28), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await refreshNotificationStatus()
        }
        .onChange(of: settings.notificationHour) { _, _ in
            rescheduleNotifications()
        }
        .onChange(of: settings.notificationMinute) { _, _ in
            rescheduleNotifications()
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
            return "Alerts on birthday mornings"
        case .denied:
            return "Permission denied — enable in Settings"
        case .notDetermined:
            return "We’ll ask for permission when needed"
        @unknown default:
            return "Alerts on birthday mornings"
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
        BirthdayNotificationManager.shared.invalidateDailyScheduleMarker()
        BirthdayNotificationManager.shared.refreshDailySchedule(
            contacts: contactsVM.contactsWithBirthday,
            fireHour: settings.notificationHour,
            fireMinute: settings.notificationMinute
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

// MARK: - Share sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
