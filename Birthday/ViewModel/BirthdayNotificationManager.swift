// BirthdayNotificationManager.swift
import Foundation
import UserNotifications

/// Schedules a *repeating* local notification at 00:00 on each contact's birthday.
final class BirthdayNotificationManager {
    static let shared = BirthdayNotificationManager()
    private init() {}

    /// Prefix so we can find/remove our requests later.
    private let requestPrefix = "bday.midnight."

    /// Ask once for notification permission.
    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                // no-op
            }
        }
    }

    /// Cancel all previously scheduled birthday notifications (just ours).
    func clearAllScheduled() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(self.requestPrefix) }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Schedule a repeating notification at **00:00** on each contact's birthday (month/day only).
    ///
    /// - Important: Uses `repeats: true` with only month/day/hour/minute components,
    ///   so this *does not* consume the "64 pending notifications" budget each year.
    func scheduleAnnualMidnight(for contacts: [Contact]) {
        let center = UNUserNotificationCenter.current()

        // First, remove our old scheduled requests so we don't duplicate
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }

            let existing = Set(
                requests.compactMap { $0.identifier.hasPrefix(self.requestPrefix) ? $0.identifier : nil }
            )
            // We’ll add new ones; to keep it simple we just remove all ours and re-add.
            center.removePendingNotificationRequests(withIdentifiers: Array(existing))

            // Now (re-)add for current contacts.
            for c in contacts {
                guard let bday = c.birthday,
                      let month = bday.month,
                      let day   = bday.day
                else { continue }

                // Build a stable identifier per contact
                // Build a stable identifier per contact
                let contactId = c.id.uuidString
                let identifier = self.requestPrefix + contactId


                // Content
                let content = UNMutableNotificationContent()
                content.title = "🎉 \(c.name)'s birthday today"
                content.body  = "Send a message?"
                content.sound = .default

                // Trigger: 00:00 every year on month/day
                var comps = DateComponents()
                comps.month = month
                comps.day   = day
                comps.hour  = 0
                comps.minute = 0
                comps.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
}
