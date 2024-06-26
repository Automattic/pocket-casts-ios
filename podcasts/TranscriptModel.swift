import Foundation
import SwiftSubtitles

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

    static func makeModel(from subtitles: Subtitles) -> TranscriptModel {
        let resultText = NSMutableAttributedString()
        var cues = [TranscriptCue]()
        for cue in subtitles.cues {
            let text = cue.text
            let attributedText = NSAttributedString(string: text + "\n")
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
}
