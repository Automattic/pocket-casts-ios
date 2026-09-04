import Foundation

/// A single piece of content on a What's New page.
///
/// A block the app doesn't know about, such as `poll`, fails to decode and is dropped by the page's
/// `LossyDecodedArray`, so the rest of the page still renders.
public enum WhatsNewBlock: Decodable, Hashable {
    case heading(WhatsNewHeading)
    case paragraph(WhatsNewParagraph)
    case image(WhatsNewImage)
    case video(WhatsNewVideo)
    case action(WhatsNewAction)

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(BlockType.self, forKey: .type) {
        case .heading:
            self = .heading(try WhatsNewHeading(from: decoder))
        case .paragraph:
            self = .paragraph(try WhatsNewParagraph(from: decoder))
        case .image:
            self = .image(try WhatsNewImage(from: decoder))
        case .video:
            self = .video(try WhatsNewVideo(from: decoder))
        case .action:
            self = .action(try WhatsNewAction(from: decoder))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }

    private enum BlockType: String, Decodable {
        case heading
        case paragraph
        case image
        case video
        case action
    }
}

public struct WhatsNewHeading: Decodable, Hashable {
    public let level: Int
    public let text: String

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 2
        text = try container.decode(String.self, forKey: .text)
    }

    private enum CodingKeys: String, CodingKey {
        case level
        case text
    }
}

public struct WhatsNewParagraph: Decodable, Hashable {
    public let content: String
}

public struct WhatsNewImage: Decodable, Hashable {
    public let url: URL
    public let width: Int?
    public let height: Int?
    public let alt: String?
}

public struct WhatsNewVideo: Decodable, Hashable {
    public struct Source: Decodable, Hashable {
        public let url: URL
        public let mimeType: String?
    }

    @LossyDecodedArray public var sources: [Source]
    public let posterUrl: URL?
    public let alt: String?
    public let captionsUrl: URL?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _sources = try container.decode(LossyDecodedArray<Source>.self, forKey: .sources)
        posterUrl = try container.decodeIfPresent(URL.self, forKey: .posterUrl)
        alt = try container.decodeIfPresent(String.self, forKey: .alt)
        captionsUrl = try container.decodeIfPresent(URL.self, forKey: .captionsUrl)
        guard !sources.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .sources, in: container, debugDescription: "A video with no playable sources")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case sources
        case posterUrl
        case alt
        case captionsUrl
    }
}

public struct WhatsNewAction: Decodable, Hashable {
    public enum Style: String, Decodable, Hashable {
        case primary
        case secondary
    }

    public let label: String
    public let url: URL
    public let style: Style

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        url = try container.decode(URL.self, forKey: .url)
        style = (try? container.decode(Style.self, forKey: .style)) ?? .primary
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case url
        case style
    }
}
