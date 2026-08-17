import Foundation

struct BirthdayWidgetData: Codable {
    let nextName: String?
    let daysToNext: Int?
    let upcomingThisMonth: Int
    let rememberedCount: Int
    /// Stable `Contact.id` for the upcoming person. Optional so older cached JSON still decodes.
    let nextContactID: String?
    /// Thumbnail JPEG/PNG for the upcoming person. Optional; omitted in older cached JSON.
    let nextThumbnail: Data?

    static let placeholder = BirthdayWidgetData(
        nextName: "Alex",
        daysToNext: 2,
        upcomingThisMonth: 3,
        rememberedCount: 5,
        nextContactID: nil,
        nextThumbnail: nil
    )

    /// Widget tap URL when a next person is available.
    var personDeepLinkURL: URL? {
        guard let nextContactID, !nextContactID.isEmpty else { return nil }
        return DeepLink.person(contactID: nextContactID).url
    }

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
enum DeepLink: Equatable {
    case todaysBirthdays
    case person(contactID: String)

    static let pendingKey = "BirthdayPal.pendingDeepLink"
    static let pendingPayloadKey = "BirthdayPal.pendingDeepLinkPayload"
    static let urlScheme = "birthdaypal"
    static let appGroupID = "group.com.archit.BirthdayPal"

    private static let todaysBirthdaysHost = "todays-birthdays"
    private static let personHost = "person"

    /// Unreserved + a few identifier-safe chars; slashes and colons are encoded.
    private static let contactIDAllowed: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()

    var url: URL {
        switch self {
        case .todaysBirthdays:
            return URL(string: "\(Self.urlScheme)://\(Self.todaysBirthdaysHost)")!
        case .person(let contactID):
            var components = URLComponents()
            components.scheme = Self.urlScheme
            components.host = Self.personHost
            let encoded = contactID.addingPercentEncoding(withAllowedCharacters: Self.contactIDAllowed) ?? contactID
            components.percentEncodedPath = "/\(encoded)"
            return components.url!
        }
    }

    static func from(url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == urlScheme else { return nil }

        let host = (url.host ?? "").lowercased()
        let pathParts = url.path
            .split(separator: "/")
            .map(String.init)

        let token: String
        if !host.isEmpty {
            token = host
        } else {
            token = pathParts.first?.lowercased() ?? ""
        }

        if token == todaysBirthdaysHost {
            return .todaysBirthdays
        }

        if token == personHost {
            let encodedID: String
            if !host.isEmpty {
                encodedID = pathParts.first ?? ""
            } else {
                encodedID = pathParts.dropFirst().first ?? ""
            }
            let id = encodedID.removingPercentEncoding ?? encodedID
            guard !id.isEmpty else { return nil }
            return .person(contactID: id)
        }

        return nil
    }

    static func consumePending() -> DeepLink? {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let raw = defaults?.string(forKey: pendingKey) else { return nil }
        let payload = defaults?.string(forKey: pendingPayloadKey)
        defaults?.removeObject(forKey: pendingKey)
        defaults?.removeObject(forKey: pendingPayloadKey)
        return fromPending(raw: raw, payload: payload)
    }

    static func setPending(_ link: DeepLink) {
        let defaults = UserDefaults(suiteName: appGroupID)
        switch link {
        case .todaysBirthdays:
            defaults?.set(todaysBirthdaysHost, forKey: pendingKey)
            defaults?.removeObject(forKey: pendingPayloadKey)
        case .person(let contactID):
            defaults?.set(personHost, forKey: pendingKey)
            defaults?.set(contactID, forKey: pendingPayloadKey)
        }
    }

    /// `todays-birthdays` or `person` + optional id payload. Also accepts legacy `person/<id>`.
    private static func fromPending(raw: String, payload: String?) -> DeepLink? {
        if raw == todaysBirthdaysHost {
            return .todaysBirthdays
        }
        if raw == personHost {
            guard let payload, !payload.isEmpty else { return nil }
            return .person(contactID: payload)
        }
        if raw.hasPrefix("\(personHost)/") {
            let id = String(raw.dropFirst(personHost.count + 1))
            guard !id.isEmpty else { return nil }
            return .person(contactID: id)
        }
        return nil
    }
}
