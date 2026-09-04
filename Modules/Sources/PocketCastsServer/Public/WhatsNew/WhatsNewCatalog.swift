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
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

/// A single item in the What's New feed.
///
/// A message with a `type` the app doesn't know about fails to decode and is dropped by the
/// catalog's `LossyDecodedArray`, so the schema can gain new types without an iOS release.
public struct WhatsNewMessage: Decodable, Hashable, Identifiable {
    public let id: String
    public let type: WhatsNewMessageType
    public let publishedAt: Date
    public let expiresAt: Date?
    public let targeting: WhatsNewTargeting
    public let summary: WhatsNewSummary
    public let content: WhatsNewContent
}

public enum WhatsNewMessageType: String, Decodable, Hashable {
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

/// How a message is presented in the feed list.
public struct WhatsNewSummary: Decodable, Hashable {
    public let title: String
    public let label: String?
    public let imageUrl: URL?
}

/// How a message is presented once it's opened.
public struct WhatsNewContent: Decodable, Hashable {
    public let title: String?
    @LossyDecodedArray public var pages: [WhatsNewPage]
}

public struct WhatsNewPage: Decodable, Hashable {
    @LossyDecodedArray public var blocks: [WhatsNewBlock]
}
