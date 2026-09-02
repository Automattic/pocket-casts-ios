import Foundation
import PocketCastsDataModel

public enum TranscriptFormat: String, CaseIterable {

    case srt = "application/srt"
    case vtt = "text/vtt"
    case textHTML = "text/html"
    case textPlain = "text/plain"
    case jsonPodcastIndex = "application/json"

    public var fileExtension: String {
        switch self {
        case .srt:
            return "srt"
        case .vtt:
            return "vtt"
        case .textHTML:
            return "html"
        case .textPlain:
            return "txt"
        case .jsonPodcastIndex:
            return "json"
        }
    }

    var possibleTypes: Set<String> {
        switch self {
        case .srt:
            return Set([self.rawValue, "application/x-subrip"])
        case .vtt:
            return Set([self.rawValue])
        case .textHTML:
            return Set([self.rawValue])
        case .textPlain:
            return Set([self.rawValue])
        case .jsonPodcastIndex:
            return Set([self.rawValue])
        }
    }

    // Transcript formats we support in order of priority of use. Untimed formats come last.
    public static let supportedFormats: [TranscriptFormat] = [.vtt, .jsonPodcastIndex, .srt, .textHTML, .textPlain]

    public static func bestTranscript(from available: [Episode.Metadata.Transcript]) -> Episode.Metadata.Transcript? {
        for format in Self.supportedFormats {
            if let transcript = available.first(where: { format.possibleTypes.contains($0.normalizedType)}) {
                return transcript
            }
        }
        return available.first
    }
}

extension Episode.Metadata.Transcript {
    /// The media type without any parameters, lowercased. For example, `Text/Plain; charset=utf-8` reads as `text/plain`.
    public var normalizedType: String {
        guard let mediaType = type.split(separator: ";", maxSplits: 1).first else { return type }
        return mediaType.trimmingCharacters(in: .whitespaces).lowercased()
    }

    public var transcriptFormat: TranscriptFormat? {
        TranscriptFormat.allCases.first { $0.possibleTypes.contains(normalizedType) }
    }
}
