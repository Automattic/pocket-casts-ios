import Foundation
import NaturalLanguage
import PocketCastsDataModel
import PocketCastsUtils

/// The transcript passage captured for a bookmark, kept alongside the transcript it was
/// taken from so it can be re-selected later.
struct BookmarkTranscriptSnippet {
    let transcript: TranscriptModel
    var range: NSRange

    var text: String {
        BookmarkTranscriptSnippetExtractor.text(in: range, of: transcript.attributedText)
    }
}

/// Extracts the transcript text surrounding a bookmark's position, used as the
/// input for generating a bookmark title.
///
/// Generated transcripts are timed against a reference copy of the episode audio
/// that dynamic ads shift away from, so the bookmark's playback time is first
/// resolved to the reference timeline (see `docs/transcripts.md`), falling back
/// to the raw playback time when a confident mapping isn't available.
struct BookmarkTranscriptSnippetExtractor {

    /// The window reaches further back than forward: by the time a user bookmarks
    /// a moment, that moment is already behind the playhead.
    static let backwardWindowSeconds: TimeInterval = 25
    static let forwardWindowSeconds: TimeInterval = 5

    /// Snippets with fewer words than this carry too little signal to generate a meaningful title from
    static let minimumWordCount = 10

    func snippet(forTime time: TimeInterval, episode: BaseEpisode) async -> BookmarkTranscriptSnippet? {
        let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: episode.parentIdentifier())
        guard let model = try? await transcriptManager.loadTranscript() else {
            return nil
        }

        // Only generated transcripts have a reference fingerprint to re-anchor against.
        var center = time
        if transcriptManager.isDisplayingGeneratedTranscript, FeatureFlag.syncedTranscripts.enabled,
           let referenceTime = await FingerprintTimingManager.shared.resolveReferenceTime(forPlaybackTime: time, episode: episode) {
            center = referenceTime
        }

        return Self.extractSnippet(from: model, at: center)
    }

    static func extractSnippet(from model: TranscriptModel, at time: TimeInterval) -> BookmarkTranscriptSnippet? {
        let windowStart = max(0, time - backwardWindowSeconds)
        let windowEnd = time + forwardWindowSeconds

        let overlapping = model.cues.filter { $0.startTime < windowEnd && $0.endTime > windowStart }
        guard let first = overlapping.first, let last = overlapping.last else {
            return nil
        }

        let location = first.characterRange.location
        let windowRange = NSRange(location: location, length: last.characterRange.upperBound - location)
        let snappedRange = snapToSentenceBoundaries(windowRange, in: model.attributedText.string)

        let snippet = BookmarkTranscriptSnippet(transcript: model, range: snappedRange)
        guard snippet.text.split(whereSeparator: \.isWhitespace).count >= minimumWordCount else {
            return nil
        }
        return snippet
    }

    static func sentenceRange(containing index: Int, in text: String) -> NSRange {
        let length = (text as NSString).length
        guard length > 0 else {
            return NSRange(location: 0, length: 0)
        }

        let clamped = min(max(index, 0), length - 1)
        return snapToSentenceBoundaries(NSRange(location: clamped, length: 1), in: text)
    }

    private static func snapToSentenceBoundaries(_ range: NSRange, in text: String) -> NSRange {
        guard let stringRange = Range(range, in: text), !stringRange.isEmpty else {
            return range
        }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        let startSentence = tokenizer.tokenRange(at: stringRange.lowerBound)
        let endSentence = tokenizer.tokenRange(at: text.index(before: stringRange.upperBound))

        let lowerBound = min(startSentence.lowerBound, stringRange.lowerBound)
        let upperBound = max(endSentence.upperBound, stringRange.upperBound)
        return NSRange(lowerBound..<upperBound, in: text)
    }

    /// The plain text within `range`, skipping the speaker-name runs interleaved between
    /// cues and collapsing the line breaks between them
    static func text(in range: NSRange, of attributedText: NSAttributedString) -> String {
        let clamped = NSIntersectionRange(range, NSRange(location: 0, length: attributedText.length))
        guard clamped.length > 0 else {
            return ""
        }

        var parts = [String]()
        let string = attributedText.string as NSString
        attributedText.enumerateAttribute(.transcriptSpeaker, in: clamped, options: []) { value, subrange, _ in
            guard value == nil else { return }
            parts.append(string.substring(with: subrange))
        }
        return parts.joined(separator: " ").split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
