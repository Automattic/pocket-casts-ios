import Foundation
import SwiftSubtitles
import PocketCastsDataModel

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
        var previousSpeaker: String = ""
        let resultText = NSMutableAttributedString()
        var cues = [TranscriptCue]()
        for cue in subtitles.cues {
            if let currentSpeaker = extractSpeaker(from: cue, format: format) {
                if currentSpeaker != previousSpeaker {
                    previousSpeaker = currentSpeaker
                    resultText.append(NSAttributedString(string: "\(currentSpeaker)\n", attributes: [.transcriptSpeaker: currentSpeaker]))
                }
            }
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

    private static func extractSpeaker(from cue: Subtitles.Cue, format: TranscriptFormat) -> String? {
        if let speaker = cue.speaker {
            return speaker
        }
        switch format {
        case .vtt:
            return regexMatch(input: cue.text, pattern: "<v (.+?)>", position: 1)
        case .srt:
            return regexMatch(input: cue.text, pattern: "^(.+?):", position: 1)
        default:
            return nil
        }
    }

    private static func regexMatch(input: String, pattern: String, position: Int = 0) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let range = NSRange(input.startIndex..., in: input)
            let results = regex.matches(in: input, range: range)
            if let result = results.first, result.range.location != NSNotFound, position <= result.numberOfRanges {
                if let range = Range(result.range(at: position), in: input) {
                    return String(input[range])
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}

extension NSAttributedString.Key {

    static var transcriptSpeaker = NSAttributedString.Key("TranscriptSpeaker")
}
