//
//  AppSettings.swift
//  Birthday
//

import Foundation
import Combine

/// Persisted user preferences for BirthdayPal.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let notificationHour = "BirthdayPal.notificationHour"
        static let notificationMinute = "BirthdayPal.notificationMinute"
        static let notificationsEnabled = "BirthdayPal.notificationsEnabled"
        static let showAgeTurning = "BirthdayPal.showAgeTurning"
        static let initialPingDays = "BirthdayPal.initialPingDays"
        static let aiAssistanceEnabled = "BirthdayPal.aiAssistanceEnabled"
    }

    /// Extra reminder N days before the birthday. `0` (or empty in Settings) means Off.
    static let initialPingDaysMax = 60

    static func clampedInitialPingDays(_ days: Int) -> Int {
        min(max(days, 0), initialPingDaysMax)
    }

    /// Replace with the real App Store ID after publish.
    static let appStoreID = "0000000000"

    static var appStoreURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }

    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }

    static let supportEmail = "ajha331@gatech.edu"

    @Published var notificationHour: Int {
        didSet { UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour) }
    }

    @Published var notificationMinute: Int {
        didSet { UserDefaults.standard.set(notificationMinute, forKey: Keys.notificationMinute) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var showAgeTurning: Bool {
        didSet { UserDefaults.standard.set(showAgeTurning, forKey: Keys.showAgeTurning) }
    }

    /// When off, Send Message skips generation and opens Messages for the contact.
    @Published var aiAssistanceEnabled: Bool {
        didSet { UserDefaults.standard.set(aiAssistanceEnabled, forKey: Keys.aiAssistanceEnabled) }
    }

    /// Extra reminder N days before the birthday. `0` disables the initial ping (day-of still fires).
    @Published var initialPingDays: Int {
        didSet {
            let clamped = Self.clampedInitialPingDays(initialPingDays)
            if clamped != initialPingDays {
                initialPingDays = clamped
                return
            }
            UserDefaults.standard.set(initialPingDays, forKey: Keys.initialPingDays)
        }
    }

    /// Binding-friendly date whose hour/minute drive notification time.
    var notificationTime: Date {
        get {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = notificationHour
            comps.minute = notificationMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notificationHour = comps.hour ?? 9
            notificationMinute = comps.minute ?? 0
        }
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.notificationHour) == nil {
            notificationHour = 9
        } else {
            notificationHour = defaults.integer(forKey: Keys.notificationHour)
        }
        if defaults.object(forKey: Keys.notificationMinute) == nil {
            notificationMinute = 0
        } else {
            notificationMinute = defaults.integer(forKey: Keys.notificationMinute)
        }
        if defaults.object(forKey: Keys.notificationsEnabled) == nil {
            notificationsEnabled = true
        } else {
            notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        }
        if defaults.object(forKey: Keys.showAgeTurning) == nil {
            showAgeTurning = true
        } else {
            showAgeTurning = defaults.bool(forKey: Keys.showAgeTurning)
        }
        if defaults.object(forKey: Keys.aiAssistanceEnabled) == nil {
            aiAssistanceEnabled = true
        } else {
            aiAssistanceEnabled = defaults.bool(forKey: Keys.aiAssistanceEnabled)
        }
        if defaults.object(forKey: Keys.initialPingDays) == nil {
            initialPingDays = 0
        } else {
            initialPingDays = Self.clampedInitialPingDays(defaults.integer(forKey: Keys.initialPingDays))
        }
    }
}
