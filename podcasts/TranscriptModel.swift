import Foundation
import SwiftSubtitles

enum TranscriptFormat: String {
    case srt = "application/srt"
    case vtt = "text/vtt"
    case textHTML = "text/html"
    case jsonPodcastIndex = "application/json"

    var fileExtension: String {
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
    static let supportedFormats: [TranscriptFormat] = [.jsonPodcastIndex, .vtt, .srt]
}

struct TranscriptCue: Sendable {
    let startTime: Double
    let endTime: Double
    let characterRange: NSRange

    @inlinable public func contains(timeInSeconds seconds: Double) -> Bool {
        seconds >= self.startTime && seconds <= self.endTime
    }
}

extension NSAttributedString: @unchecked Sendable {

}

struct TranscriptModel: Sendable {

    let attributedText: NSAttributedString
    let cues: [TranscriptCue]

    static func makeModel(from transcriptText: String, format: TranscriptFormat) -> TranscriptModel? {
        if format == .textHTML {
            let filteredText = ComposeFilter.htmlFilter.filter(transcriptText).trim()
            return TranscriptModel(attributedText: NSAttributedString(string: filteredText), cues: [])
        }
        guard let subtitles = try? Subtitles(content: transcriptText, expectedExtension: format.fileExtension) else {
            return nil
        }

        let resultText = NSMutableAttributedString()
        var cues = [TranscriptCue]()
        for cue in subtitles.cues {
            let text = cue.text

            let filteredText: String = ComposeFilter.transcriptFilter.filter(text)

            let attributedText = NSAttributedString(string: filteredText)
            let startPosition = resultText.length
            let endPosition = attributedText.length
            let range = NSRange(location: startPosition, length: endPosition)
            resultText.append(attributedText)
            let entry = TranscriptCue(startTime: cue.startTimeInSeconds, endTime: cue.endTimeInSeconds, characterRange: range)
            cues.append(entry)
        }

        return TranscriptModel(attributedText: resultText, cues: cues)
    }

    @inlinable public func firstCue(containing secondsValue: Double) -> TranscriptCue? {
        self.cues.first { $0.contains(timeInSeconds: secondsValue) }
    }

    var isEmtpy: Bool {
        return attributedText.string.trim().isEmpty
    }
}
