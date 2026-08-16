import Foundation

struct BirthdayWidgetData: Codable {
    let nextName: String?
    let daysToNext: Int?
    let upcomingThisMonth: Int
    let rememberedCount: Int

    static let placeholder = BirthdayWidgetData(
        nextName: "Alex",
        daysToNext: 2,
        upcomingThisMonth: 3,
        rememberedCount: 5
    )

    static func loadFromShared() -> BirthdayWidgetData {
        // App Group must match ContactViewModel.updateWidgetData()
        let defaults = UserDefaults(suiteName: "group.com.archit.BirthdayPal")
        guard
            let data = defaults?.data(forKey: "BirthdayWidgetData"),
            let decoded = try? JSONDecoder().decode(BirthdayWidgetData.self, from: data)
        else {
            return .placeholder
        }
        return decoded
    }
}

/// Deep links shared by the app and Control Center / widgets.
enum DeepLink: String {
    case todaysBirthdays = "todays-birthdays"

    static let pendingKey = "BirthdayPal.pendingDeepLink"
    static let urlScheme = "birthdaypal"
    static let appGroupID = "group.com.archit.BirthdayPal"

    var url: URL {
        URL(string: "\(Self.urlScheme)://\(rawValue)")!
    }

    static func from(url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == urlScheme else { return nil }
        let host = url.host?.lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let token = (host?.isEmpty == false ? host : path) ?? ""
        return DeepLink(rawValue: token)
    }

    static func consumePending() -> DeepLink? {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let raw = defaults?.string(forKey: pendingKey) else { return nil }
        defaults?.removeObject(forKey: pendingKey)
        return DeepLink(rawValue: raw)
    }

    static func setPending(_ link: DeepLink) {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(link.rawValue, forKey: pendingKey)
    }
}
