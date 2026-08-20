import Foundation
import SwiftSubtitles
import PocketCastsDataModel
import PocketCastsUtils

struct TranscriptCue: Sendable {
    let startTime: Double
    let endTime: Double
    let characterRange: NSRange

    @inlinable public func contains(timeInSeconds seconds: Double) -> Bool {
        seconds >= self.startTime && seconds <= self.endTime
    }
}

extension NSAttributedString: @retroactive @unchecked Sendable {
}

struct TranscriptModel: Sendable {

    let attributedText: NSAttributedString
    let cues: [TranscriptCue]
    let type: String
    let hasJavascript: Bool

    static func makeModel(from transcriptText: String, format: TranscriptFormat) -> TranscriptModel? {
        let trimmedTranscript = transcriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            return nil
        }
        if format == .textHTML {
            let filteredText = ComposeFilter.htmlFilter.filter(transcriptText).trim()
            return TranscriptModel(attributedText: NSAttributedString(string: filteredText), cues: [], type: format.rawValue, hasJavascript: transcriptText.contains("<script type=\"text/javascript\">"))
        }
        let subtitles: Subtitles? = {
            do {
                if format == .jsonPodcastIndex {
                    return try parseJSONSubtitles(from: transcriptText)
                }
                return try Subtitles(content: transcriptText, expectedExtension: format.fileExtension)
            }
            catch {
                FileLog.shared.addMessage("Transcripts Parsing:\(error)")
                return nil
            }
        }()
        guard let subtitles else {
            return nil
        }
        var previousSpeaker: String = ""
        let resultText = NSMutableAttributedString()
        var cues = [TranscriptCue]()
        for cue in subtitles.cues {
            if let currentSpeaker = extractSpeaker(from: cue, format: format) {
                if currentSpeaker != previousSpeaker {
                    previousSpeaker = currentSpeaker
                    resultText.append(NSAttributedString(string: "\n\(currentSpeaker)\n", attributes: [.transcriptSpeaker: currentSpeaker]))
                }
            }
            let text = cue.text

            let filteredText: String = ComposeFilter.transcriptFilter.filter(text)
            if filteredText.trim().isEmpty {
                continue
            }
            let attributedText = NSAttributedString(string: filteredText)
            let startPosition = resultText.length
            let endPosition = attributedText.length
            let range = NSRange(location: startPosition, length: endPosition)
            resultText.append(attributedText)
            let entry = TranscriptCue(startTime: cue.startTimeInSeconds, endTime: cue.endTimeInSeconds, characterRange: range)
            cues.append(entry)
        }

        return TranscriptModel(attributedText: resultText, cues: cues, type: format.rawValue, hasJavascript: false)
    }

    @inlinable public func firstCue(containing secondsValue: Double) -> TranscriptCue? {
        self.cues.first { $0.contains(timeInSeconds: secondsValue) }
    }

    /// The cue the character at `characterIndex` reads as part of.
    ///
    /// A position that lands on a speaker name, or in the gap between two cues, belongs to
    /// the cue that follows it rather than the one that ended before it.
    func cue(atCharacterIndex characterIndex: Int) -> TranscriptCue? {
        cues.first { NSLocationInRange(characterIndex, $0.characterRange) || $0.characterRange.location >= characterIndex }
    }

    var isEmtpy: Bool {
        return attributedText.string.trim().isEmpty
    }

    /// Parses a JSON transcript into `Subtitles`, supporting both the Podcast Index
    /// format and the Flightcast format (an embedded WEBVTT document or timed
    /// plain-text segments). Flightcast transcripts arrive with the same
    /// `application/json` type as Podcast Index but carry `text`/`start`/`end`
    /// segments (and often a `vtt` field) instead of `body`/`startTime`/`endTime`.
    private static func parseJSONSubtitles(from text: String) throws -> Subtitles {
        guard
            let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            // Not a JSON object: fall back to the Podcast Index decoder.
            return try Subtitles(content: text, expectedExtension: TranscriptFormat.jsonPodcastIndex.fileExtension)
        }

        let segments = (json["segments"] as? [Any])?.compactMap { $0 as? [String: Any] } ?? []

        // Podcast Index style: segments carry `body` (the `speaker` field is
        // optional, so we key off `body`, which the decoder requires).
        if let first = segments.first, first["body"] is String {
            return try Subtitles(content: text, expectedExtension: TranscriptFormat.jsonPodcastIndex.fileExtension)
        }

        // Flightcast: prefer the embedded WEBVTT document as it carries cue timing.
        if let vtt = json["vtt"] as? String, vtt.contains("WEBVTT") {
            return try Subtitles(content: vtt, expectedExtension: TranscriptFormat.vtt.fileExtension)
        }

        // Flightcast fallback: timed segments carrying plain text. Ignore any
        // segment without a string `text` so we never render invalid entries.
        let cues: [Subtitles.Cue] = segments.compactMap { segment in
            guard let segmentText = segment["text"] as? String else { return nil }
            let start = (segment["start"] as? NSNumber)?.doubleValue ?? 0
            let end = (segment["end"] as? NSNumber)?.doubleValue ?? start
            return Subtitles.Cue(startTimeInSeconds: start, endTimeInSeconds: end, text: segmentText)
        }
        guard !cues.isEmpty else {
            throw TranscriptError.failedToParse
        }
        return Subtitles(cues)
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
