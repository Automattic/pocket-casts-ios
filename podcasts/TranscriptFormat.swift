import Foundation
import PocketCastsDataModel

public enum TranscriptFormat: String, CaseIterable {

    case srt = "application/srt"
    case vtt = "text/vtt"
    case textHTML = "text/html"
    case jsonPodcastIndex = "application/json"

    public var fileExtension: String {
        switch self {
        case .srt:
            return "srt"
        case .vtt:
            return "vtt"
        case .textHTML:
            return "html"
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
        case .jsonPodcastIndex:
            return Set([self.rawValue])
        }
    }

    // Transcript formats we support in order of priority of use
    public static let supportedFormats: [TranscriptFormat] = [.vtt, .jsonPodcastIndex, .srt, .textHTML]

    public static func bestTranscript(from available: [Episode.Metadata.Transcript]) -> Episode.Metadata.Transcript? {
        for format in Self.supportedFormats {
            if let transcript = available.first(where: { format.possibleTypes.contains($0.type)}) {
                return transcript
            }
        }
        return available.first
    }
}

extension Episode.Metadata.Transcript {
    public var transcriptFormat: TranscriptFormat? {
        for format in TranscriptFormat.allCases {
            if format.possibleTypes.contains(type) {
                return format
            }
        }
        return nil
    }
}
