//
//  NotificationsManager.swift
//  Birthday
//
//  Created by Archit Lakhani on 11/12/25.
//

// NotificationsManager.swift
import Foundation
import UserNotifications

final class NotificationsManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationsManager()
    private override init() { super.init() }

    /// Call once at app start (sets delegate + requests permission)
    func setUp() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            // You could inspect errors/result here if you want
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

    /// Rebuild all birthday notifications from your contacts.
    /// - Parameters:
    ///   - contacts: your `Contact` models
    ///   - fireHour/minute: daily time to notify (local time)
    func refreshBirthdayNotifications(
        contacts: [Contact],
        fireHour: Int = 19,
        fireMinute: Int = 10
    ) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { pending in
            // Remove our previously scheduled birthday notifications
            let toRemove = pending
                .filter { $0.identifier.hasPrefix("bday.") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: toRemove)

            for contact in contacts {
                guard
                    let comps = contact.birthday,
                    let month = comps.month,
                    let day = comps.day
                else { continue }

                // Stable identifier per contact (adjust if your Contact has a real `id`)
                let baseID = "bday.\(self.identifierKey(for: contact))"

                // Repeating every year on month/day at fireHour:fireMinute
                var triggerComps = DateComponents()
                triggerComps.month = month
                triggerComps.day = day
                triggerComps.hour = fireHour
                triggerComps.minute = fireMinute

                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)

                let content = UNMutableNotificationContent()
                content.title = "🎂 It’s \(contact.name)’s birthday!"
                content.body = "Send them a quick message."
                content.sound = .default
                content.threadIdentifier = "birthday"

                let request = UNNotificationRequest(identifier: baseID, content: content, trigger: trigger)
                center.add(request)

                // If their birthday is TODAY and the scheduled time already passed,
                // also fire a one-off notification immediately so you don’t miss it.
                if self.isToday(month: month, day: day) && self.hasTodayTimePassed(hour: fireHour, minute: fireMinute) {
                    let instant = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                    let nowRequest = UNNotificationRequest(
                        identifier: baseID + ".now",
                        content: content,
                        trigger: instant
                    )
                    center.add(nowRequest)
                }
            }
        }
    }

    // MARK: - Helpers

    private func identifierKey(for contact: Contact) -> String {
        // Prefer a stable unique ID if your Contact has one (e.g., UUID/string).
        // return String(describing: contact.id)
        let m = contact.birthday?.month ?? 0
        let d = contact.birthday?.day ?? 0
        return "\(contact.name)|\(m)-\(d)"
    }

    private func isToday(month: Int, day: Int) -> Bool {
        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        return today.month == month && today.day == day
    }

    private func hasTodayTimePassed(hour: Int, minute: Int) -> Bool {
        var comps = Calendar.current.dateComponents([.year,.month,.day], from: Date())
        comps.hour = hour
        comps.minute = minute
        let target = Calendar.current.date(from: comps) ?? Date()
        return Date() >= target
    }
}
