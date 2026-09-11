import Foundation

/// The What's New feed published to the CDN for a single platform and locale.
public struct WhatsNewCatalog: Decodable, Hashable {
    public let schemaVersion: Int
    public let generatedAt: Date?
    public let platform: String?
    public let locale: String?
    @LossyDecodedArray public var messages: [WhatsNewMessage]

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = WhatsNewCatalog.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an ISO 8601 date: \(string)")
            }
            return date
        }
        return decoder
    }()

    /// Parses an ISO 8601 timestamp with or without fractional seconds.
    private static func date(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

/// A single item in the What's New feed.
///
/// A message is all or nothing: a `type` this version doesn't know, or content its type doesn't
/// allow, fails to decode and is dropped by the catalog's `LossyDecodedArray`. The feed is left
/// with the messages around it rather than a half-drawn one, and the schema can gain new types
/// without an iOS release.
public struct WhatsNewMessage: Decodable, Hashable, Identifiable {
    public let id: String
    public let type: WhatsNewMessageType
    public let publishedAt: Date
    public let expiresAt: Date?
    public let targeting: WhatsNewTargeting

    /// The one title the message is known by, shown in the feed and on every one of its pages.
    public let title: String

    /// What the message carries beneath its title, in the shape its type calls for.
    public let content: WhatsNewContent

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(WhatsNewMessageType.self, forKey: .type)
        publishedAt = try container.decode(Date.self, forKey: .publishedAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        targeting = try container.decode(WhatsNewTargeting.self, forKey: .targeting)
        title = try container.decodeNonEmptyString(forKey: .title)
        content = try WhatsNewContent(from: decoder, type: type)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case publishedAt
        case expiresAt
        case targeting
        case title
    }
}

/// The kinds of message the feed publishes, each of which picks the layout it's drawn in.
public enum WhatsNewMessageType: String, Decodable, Hashable, CaseIterable {
    case newFeature = "new_feature"
    case tip
    case announcement
    case knownIssue = "known_issue"
    case research
}

/// The rules a client applies before a message can be shown.
public struct WhatsNewTargeting: Decodable, Hashable {
    /// The audiences as published, including any this version of the app doesn't understand.
    @LossyDecodedArray public var rawAudiences: [String]
    public let minimumAppVersion: String?

    /// The audiences this version of the app understands.
    ///
    /// Fewer of these than there are `rawAudiences` means the message is aimed at a tier this
    /// version can't evaluate, which isn't the same as a message that isn't aimed at anyone.
    public var audiences: [WhatsNewAudience] {
        rawAudiences.compactMap(WhatsNewAudience.init(rawValue:))
    }

    /// Whether a user in `audience` is targeted by the message.
    ///
    /// A message with no audiences is for everyone. A message aimed only at audiences this version
    /// doesn't understand is for nobody, so an unknown tier hides the message rather than showing
    /// it to every user.
    public func targets(_ audience: WhatsNewAudience) -> Bool {
        rawAudiences.isEmpty || rawAudiences.contains(audience.rawValue)
    }

    private enum CodingKeys: String, CodingKey {
        case rawAudiences = "audiences"
        case minimumAppVersion
    }
}

public enum WhatsNewAudience: String, Decodable, Hashable {
    case free
    case plus
    case patron
}
