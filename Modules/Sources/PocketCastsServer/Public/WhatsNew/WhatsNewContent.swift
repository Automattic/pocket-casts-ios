import Foundation

/// What a message carries beneath its shared title.
///
/// The catalog publishes a small set of curated layouts rather than free-form content: a message's
/// type decides which of these shapes it has, and neither shape can be mixed with the other.
public enum WhatsNewContent: Hashable {
    /// The ordered pages of a `new_feature`, `tip`, `announcement`, or `known_issue` message.
    case pages([WhatsNewPage])

    /// The single poll a `research` message is built around.
    case research(WhatsNewResearch)

    init(from decoder: any Decoder, type: WhatsNewMessageType) throws {
        switch type {
        case .newFeature, .tip, .announcement, .knownIssue:
            self = .pages(try WhatsNewPage.pages(from: decoder))
        case .research:
            self = .research(try WhatsNewResearch(from: decoder))
        }
    }

    /// The pages of a standard message, in the order they were published, or none for research.
    public var pages: [WhatsNewPage] {
        guard case .pages(let pages) = self else { return [] }
        return pages
    }

    /// The poll a research message asks, or `nil` for anything else.
    public var research: WhatsNewResearch? {
        guard case .research(let research) = self else { return nil }
        return research
    }
}

/// One page of a standard message, drawn in the predefined layout its type shares.
///
/// A page has no identity in the contract; its position in the message is what it's known by. Every
/// field a page can carry is either required or a single optional action, so there's no such thing
/// as a page with nothing to draw.
public struct WhatsNewPage: Decodable, Hashable {
    public let image: WhatsNewImage
    public let heading: String
    public let description: String

    /// The one call to action the page can carry, which the client decides where to put.
    public let action: WhatsNewAction?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        image = try container.decode(WhatsNewImage.self, forKey: .image)
        heading = try container.decodeNonEmptyString(forKey: .heading)
        description = try container.decodeNonEmptyString(forKey: .description)
        action = try container.decodeIfPresent(WhatsNewAction.self, forKey: .action)
    }

    private enum CodingKeys: String, CodingKey {
        case image
        case heading
        case description
        case action
    }

    /// The message's pages, which a standard message has at least one of.
    static func pages(from decoder: any Decoder) throws -> [WhatsNewPage] {
        let container = try decoder.container(keyedBy: PagesCodingKeys.self)
        let pages = try container.decode([WhatsNewPage].self, forKey: .pages)
        guard !pages.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .pages, in: container, debugDescription: "A message with no pages")
        }
        return pages
    }

    private enum PagesCodingKeys: String, CodingKey {
        case pages
    }
}

/// The image a page is built around, uploaded through the What's New admin workflow and published
/// to the CDN as a WebP.
public struct WhatsNewImage: Decodable, Hashable {
    public let url: URL
    public let width: Int
    public let height: Int

    /// What the image shows, for anyone who can't see it.
    public let alt: String

    /// The shape the image was published at, so a page can leave room for it before it arrives.
    public var aspectRatio: Double {
        Double(width) / Double(height)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        alt = try container.decodeNonEmptyString(forKey: .alt)
        guard width > 0, height > 0 else {
            throw DecodingError.dataCorruptedError(forKey: .width, in: container, debugDescription: "An image with no size: \(width)×\(height)")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case url
        case width
        case height
        case alt
    }
}

/// A page's call to action, which names a behaviour rather than pointing anywhere.
///
/// The catalog is public, declarative content rather than a format the app executes, so an action
/// carries an event name every client maps to behaviour of its own. An event this version doesn't
/// implement costs the page its button and nothing else.
public struct WhatsNewAction: Decodable, Hashable {
    public let event: String
    public let label: String

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decodeNonEmptyString(forKey: .event)
        label = try container.decodeNonEmptyString(forKey: .label)
    }

    private enum CodingKeys: String, CodingKey {
        case event
        case label
    }
}

/// The poll a `research` message asks, and the text introducing it.
public struct WhatsNewResearch: Decodable, Hashable {
    /// What the message says before the question, which not every research message has.
    public let description: String?

    public let poll: WhatsNewPoll

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decodeNonEmptyStringIfPresent(forKey: .description)
        poll = try container.decode(WhatsNewPoll.self, forKey: .poll)
    }

    private enum CodingKeys: String, CodingKey {
        case description
        case poll
    }
}

/// A single question and the answers it can be given.
///
/// The poll has an identity of its own, separate from the message it's asked in, because whether an
/// account has answered is kept apart from whether it has read the message.
public struct WhatsNewPoll: Decodable, Hashable {
    public let pollId: String

    /// The readable key the poll's answers are grouped under in analytics, which stays the same
    /// however the question is reworded or translated.
    public let pollKey: String

    public let question: String

    /// The answers, in the order they're meant to be offered.
    public let options: [Option]

    public struct Option: Decodable, Hashable, Identifiable {
        public let id: String

        /// The readable key this answer is counted under, which outlives its label.
        public let pollOptionKey: String

        public let label: String

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            pollOptionKey = try container.decodeNonEmptyString(forKey: .pollOptionKey)
            label = try container.decodeNonEmptyString(forKey: .label)
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case pollOptionKey
            case label
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pollId = try container.decode(String.self, forKey: .pollId)
        pollKey = try container.decodeNonEmptyString(forKey: .pollKey)
        question = try container.decodeNonEmptyString(forKey: .question)
        options = try container.decode([Option].self, forKey: .options)
        guard !options.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .options, in: container, debugDescription: "A poll with nothing to answer")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case pollId
        case pollKey
        case question
        case options
    }
}

extension KeyedDecodingContainer {
    /// Decodes a string the contract requires to say something, which an empty one doesn't.
    func decodeNonEmptyString(forKey key: Key) throws -> String {
        let value = try decode(String.self, forKey: key).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "An empty \(key.stringValue)")
        }
        return value
    }

    /// Decodes an optional string, treating one that says nothing as one that isn't there.
    func decodeNonEmptyStringIfPresent(forKey key: Key) throws -> String? {
        let value = try decodeIfPresent(String.self, forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }
}
