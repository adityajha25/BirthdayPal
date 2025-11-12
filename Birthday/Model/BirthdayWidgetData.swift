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
