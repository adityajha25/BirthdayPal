import Foundation
import UserNotifications

/// Schedules local notifications at the user's chosen fire time for:
/// - each contact's **next** birthday (day-of)
/// - an **initial ping** N days before, when enabled in settings
///
/// Notifications are scheduled for their actual future fire dates so they fire
/// without the app being opened on that day. iOS allows at most 64 pending
/// local notifications; the nearest ones are kept when the list overflows.
final class BirthdayNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BirthdayNotificationManager()

    /// iOS cap on pending local notification requests.
    private static let maxPendingNotifications = 64

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

    /// Loads birthday contacts and reschedules when notifications are enabled.
    /// Safe to call on every app launch (including before the UI appears).
    func refreshScheduleFromContactsIfEnabled() {
        let settings = AppSettings.shared
        guard settings.notificationsEnabled else {
            clearAllBirthdayNotifications()
            return
        }

        ContactsManager().fetchContacts(scope: .withBirthdaysOnly) { [weak self] result in
            guard let self else { return }
            if case .success(let contacts) = result {
                self.refreshDailySchedule(contacts: contacts)
            }
        }
    }

    /// Idempotent refresh using `AppSettings` fire time and initial-ping days.
    func refreshDailySchedule(contacts: [Contact]) {
        let settings = AppSettings.shared
        guard settings.notificationsEnabled else {
            clearAllBirthdayNotifications()
            return
        }
        refreshDailySchedule(
            contacts: contacts,
            fireHour: settings.notificationHour,
            fireMinute: settings.notificationMinute,
            initialPingDays: settings.initialPingDays
        )
    }

    /// Idempotent: safe to call on every app launch and whenever settings or contacts change.
    /// Schedules day-of and initial-ping notifications on their actual future fire dates.
    func refreshDailySchedule(
        contacts: [Contact],
        fireHour: Int,
        fireMinute: Int,
        initialPingDays: Int
    ) {
        let pingDays = AppSettings.clampedInitialPingDays(initialPingDays)
        let calendar = Calendar.current
        let now = Date()

        struct PlannedNotification {
            let contact: Contact
            let kind: NotificationKind
            let fireDate: Date
            let id: String
        }

        var planned: [PlannedNotification] = []

        for contact in contacts {
            guard let observance = contact.nextObservanceDate(from: now, calendar: calendar) else {
                continue
            }

            if let fireDate = Self.fireDate(
                on: observance,
                hour: fireHour,
                minute: fireMinute,
                calendar: calendar
            ), fireDate > now {
                planned.append(
                    PlannedNotification(
                        contact: contact,
                        kind: .dayOf,
                        fireDate: fireDate,
                        id: Self.notificationId(
                            for: contact,
                            fireDate: fireDate,
                            kind: .dayOf,
                            prefix: idPrefix
                        )
                    )
                )
            }

            if pingDays > 0,
               let pingDay = calendar.date(byAdding: .day, value: -pingDays, to: observance),
               let fireDate = Self.fireDate(
                   on: pingDay,
                   hour: fireHour,
                   minute: fireMinute,
                   calendar: calendar
               ), fireDate > now {
                planned.append(
                    PlannedNotification(
                        contact: contact,
                        kind: .comingUp,
                        fireDate: fireDate,
                        id: Self.notificationId(
                            for: contact,
                            fireDate: fireDate,
                            kind: .comingUp,
                            prefix: idPrefix
                        )
                    )
                )
            }
        }

        planned.sort { $0.fireDate < $1.fireDate }
        let toSchedule = Array(planned.prefix(Self.maxPendingNotifications))

        UNUserNotificationCenter.current().getPendingNotificationRequests { [idPrefix] requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ours)

            for item in toSchedule {
                let content = UNMutableNotificationContent()
                content.title = item.kind.title
                content.body = item.kind.body(for: item.contact.name, daysUntil: pingDays)
                content.sound = .default

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: item.fireDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
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

    private static func fireDate(
        on day: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }

    /// Stable ID per contact per fire date per kind: "bday-today-<id>-MMDD-YYYY"
    private static func notificationId(
        for contact: Contact,
        fireDate: Date,
        kind: NotificationKind,
        prefix: String
    ) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: fireDate)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        let token = sanitize(contact.id)
        return "\(prefix)\(kind.idToken)-\(token)-\(String(format: "%02d%02d-%04d", m, d, y))"
    }

    private static func sanitize(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return s.lowercased().unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }.reduce(into: "") { $0.append($1) }
    }
}
