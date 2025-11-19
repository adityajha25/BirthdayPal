import Foundation
import UserNotifications

/// Schedules *one* local notification at a chosen time (default 9:00)
/// for each person whose birthday is *today*. Uses stable identifiers to avoid duplicates.
final class BirthdayNotificationManager {
    static let shared = BirthdayNotificationManager()

    private init() {}

    private let lastScheduledKey = "BirthdayPal.lastScheduledYMD"
    private let idPrefix = "bday-" // used to find/remove only our notifications

    // MARK: Public API

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Idempotent: safe to call on every app launch. It re-schedules only *today’s* 9:00 notifications.
    func refreshDailySchedule(
        contacts: [Contact],
        fireHour: Int = 9,
        fireMinute: Int = 0
    ) {
        let todayYMD = Self.ymdString(Date())
        // If we've already scheduled today AND our IDs are stable, we can skip.
        // Still, we re-create requests after cleaning duplicates so multiple calls stay idempotent.
        if UserDefaults.standard.string(forKey: lastScheduledKey) == todayYMD {
            // We’ll still dedupe below; early return here is optional.
            // return
        }

        let todaysContacts = contacts.filter { $0.daysToBirthday == 0 }

        // Build all the identifiers we intend to use (one per contact)
        let ids = todaysContacts.map { Self.notificationId(for: $0, on: Date(), prefix: idPrefix) }

        // Remove any existing requests *for these same IDs* so we replace instead of duping
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        // Schedule (only if there are birthdays today)
        guard !todaysContacts.isEmpty else {
            UserDefaults.standard.set(todayYMD, forKey: lastScheduledKey)
            return
        }

        let now = Date()
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = fireHour
        dateComponents.minute = fireMinute

        // If it's already past the fire time today, deliver immediately (3s) instead of missing the day
        let alreadyPastFireTime: Bool = {
            if let at = calendar.date(from: dateComponents) {
                return now >= at
            }
            return false
        }()

        for contact in todaysContacts {
            let title = "🎂 Birthday today"
            let name = contact.name
            let body = "It's \(name)'s birthday today!"

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let requestId = Self.notificationId(for: contact, on: now, prefix: idPrefix)

            let trigger: UNNotificationTrigger
            if alreadyPastFireTime {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            } else {
                let t = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                trigger = t
            }

            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }

        UserDefaults.standard.set(todayYMD, forKey: lastScheduledKey)
    }

    /// Optional helper to remove only our birthday notifications (does not clear other app notifications).
    func clearAllBirthdayNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(self.idPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ours)
        }
    }

    /// Debug print
    func debugPrintPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("🔔 Pending (\(requests.count)):")
            for r in requests {
                print(" - \(r.identifier)")
            }
        }
    }

    // MARK: Helpers

    private static func ymdString(_ date: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    /// Stable, human-readable ID per contact per day: "bday-<sanitized-name>-MMDD-YYYY"
    private static func notificationId(for contact: Contact, on date: Date, prefix: String) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        let name = sanitize(contact.name)
        return "\(prefix)\(name)-\(String(format: "%02d%02d-%04d", m, d, y))"
    }

    private static func sanitize(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return s.lowercased().unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }.reduce(into: "") { $0.append($1) }
    }
}
