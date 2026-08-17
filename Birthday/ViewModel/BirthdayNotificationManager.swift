import Foundation
import UserNotifications

/// Schedules local notifications at the user's chosen fire time for:
/// - people whose birthday is **today** (always, when notifications are on)
/// - people whose birthday is in **X days**, when an initial ping is enabled
///
/// Live path: day-of + initial ping via `refreshDailySchedule` after contact load.
final class BirthdayNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BirthdayNotificationManager()

    private override init() {
        super.init()
    }

    private let idPrefix = "bday-" // used to find/remove only our notifications

    // MARK: Public API

    /// Call once at app start (sets foreground-banner delegate + requests permission).
    func setUp() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        requestAuthorizationIfNeeded()
    }

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    // Show banner even when app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    /// Idempotent daily refresh using `AppSettings` fire time and initial-ping days.
    func refreshDailySchedule(contacts: [Contact]) {
        let settings = AppSettings.shared
        refreshDailySchedule(
            contacts: contacts,
            fireHour: settings.notificationHour,
            fireMinute: settings.notificationMinute,
            initialPingDays: settings.initialPingDays
        )
    }

    /// Idempotent: safe to call on every app launch. Schedules today's fire-time notifications
    /// for day-of birthdays and, when `initialPingDays > 0`, birthdays that are exactly that many days out.
    func refreshDailySchedule(
        contacts: [Contact],
        fireHour: Int,
        fireMinute: Int,
        initialPingDays: Int
    ) {
        let dayOfContacts = contacts.filter { $0.daysToBirthday == 0 }
        let pingDays = AppSettings.clampedInitialPingDays(initialPingDays)
        let comingUpContacts: [Contact]
        if pingDays > 0 {
            comingUpContacts = contacts.filter { $0.daysToBirthday == pingDays }
        } else {
            comingUpContacts = []
        }

        let dayOfIDs = dayOfContacts.map { Self.notificationId(for: $0, on: Date(), kind: .dayOf, prefix: idPrefix) }
        let comingUpIDs = comingUpContacts.map { Self.notificationId(for: $0, on: Date(), kind: .comingUp, prefix: idPrefix) }
        let intendedIDs = Set(dayOfIDs + comingUpIDs)

        UNUserNotificationCenter.current().getPendingNotificationRequests { [idPrefix] requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            // Drop leftovers (e.g. ping days changed) so we don't stack duplicates.
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ours)

            guard !dayOfContacts.isEmpty || !comingUpContacts.isEmpty else {
                return
            }

            let now = Date()
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.hour = fireHour
            dateComponents.minute = fireMinute

            let alreadyPastFireTime: Bool = {
                if let at = calendar.date(from: dateComponents) {
                    return now >= at
                }
                return false
            }()

            func addRequest(contact: Contact, kind: NotificationKind) {
                let content = UNMutableNotificationContent()
                content.title = kind.title
                content.body = kind.body(for: contact.name, daysUntil: pingDays)
                content.sound = .default

                let requestId = Self.notificationId(for: contact, on: now, kind: kind, prefix: idPrefix)
                guard intendedIDs.contains(requestId) else { return }

                let trigger: UNNotificationTrigger
                if alreadyPastFireTime {
                    trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                } else {
                    trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                }

                let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }

            for contact in dayOfContacts {
                addRequest(contact: contact, kind: .dayOf)
            }
            for contact in comingUpContacts {
                addRequest(contact: contact, kind: .comingUp)
            }
        }
    }

    /// Optional helper to remove only our birthday notifications (does not clear other app notifications).
    func clearAllBirthdayNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(self.idPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ours)
        }
    }

    // MARK: Helpers

    private enum NotificationKind {
        case dayOf
        case comingUp

        var idToken: String {
            switch self {
            case .dayOf: return "today"
            case .comingUp: return "soon"
            }
        }

        var title: String {
            switch self {
            case .dayOf: return "Birthday today"
            case .comingUp: return "Birthday coming up"
            }
        }

        func body(for name: String, daysUntil: Int) -> String {
            switch self {
            case .dayOf:
                return "It's \(name)'s birthday today"
            case .comingUp:
                if daysUntil == 1 {
                    return "\(name)'s birthday is in 1 day"
                }
                return "\(name)'s birthday is in \(daysUntil) days"
            }
        }
    }

    /// Stable ID per contact per day per kind: "bday-today-<name>-MMDD-YYYY"
    private static func notificationId(
        for contact: Contact,
        on date: Date,
        kind: NotificationKind,
        prefix: String
    ) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        let name = sanitize(contact.name)
        return "\(prefix)\(kind.idToken)-\(name)-\(String(format: "%02d%02d-%04d", m, d, y))"
    }

    private static func sanitize(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return s.lowercased().unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }.reduce(into: "") { $0.append($1) }
    }
}
