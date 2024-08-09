import Foundation
import PocketCastsDataModel

public enum TranscriptFormat: String {

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

    // Transcript formats we support in order of priority of use
    public static let supportedFormats: [TranscriptFormat] = [.vtt, .srt, .jsonPodcastIndex, .textHTML]

    public static func bestTranscript(from available: [Episode.Metadata.Transcript]) -> Episode.Metadata.Transcript? {
        for format in Self.supportedFormats {
            if let transcript = available.first(where: { $0.type == format.rawValue}) {
                return transcript
            }
        }
        return available.first
    }
}

extension Episode.Metadata.Transcript {
    public var transcriptFormat: TranscriptFormat? {
        return TranscriptFormat(rawValue: self.type)
    }
}
