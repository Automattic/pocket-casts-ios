import Foundation
import NaturalLanguage
import PocketCastsDataModel
import PocketCastsUtils

/// Extracts the transcript text surrounding a bookmark's position, used as the
/// input for generating a bookmark title/summary.
///
/// Generated transcripts are timed against a reference copy of the episode
/// audio, which dynamic ads shift relative to what the listener actually
/// hears — so the bookmark's playback time is first resolved to the reference
/// timeline by fingerprinting the local audio around it (see
/// `docs/transcripts.md`), falling back to the raw playback time when a
/// confident mapping isn't available.
struct BookmarkTranscriptSnippetExtractor {

    /// The capture window is asymmetric: by the time a user acts on a moment
    /// they want to keep, that moment is already behind the playhead — so we
    /// reach much further back than forward.
    static let backwardWindowSeconds: TimeInterval = 25
    static let forwardWindowSeconds: TimeInterval = 5

    /// Snippets with fewer words than this carry too little signal to generate
    /// a meaningful title from, so extraction aborts instead.
    static let minimumWordCount = 10

    /// Extracts the transcript snippet around `time` (a playback-timeline
    /// position, e.g. `Bookmark.time`) for the given episode. Returns nil when
    /// the episode has no usable timed transcript or the window holds fewer
    /// than `minimumWordCount` words.
    func snippet(forTime time: TimeInterval, episode: BaseEpisode) async -> String? {
        let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: episode.parentIdentifier())
        guard let model = try? await transcriptManager.loadTranscript() else {
            return nil
        }

        // Only generated transcripts have a reference fingerprint published, so
        // only they can (and need to) be re-anchored to the reference timeline.
        var center = time
        if transcriptManager.isDisplayingGeneratedTranscript, FeatureFlag.syncedTranscripts.enabled,
           let referenceTime = await FingerprintTimingManager.shared.resolveReferenceTime(forPlaybackTime: time, episode: episode) {
            center = referenceTime
        }

        return Self.extractSnippet(from: model, at: center)
    }

    /// Pure extraction: the cues overlapping `[time - backward, time + forward]`,
    /// expanded outward to whole sentences, with speaker lines excluded and
    /// whitespace normalized.
    static func extractSnippet(from model: TranscriptModel, at time: TimeInterval) -> String? {
        let windowStart = max(0, time - backwardWindowSeconds)
        let windowEnd = time + forwardWindowSeconds

        let overlapping = model.cues.filter { $0.startTime < windowEnd && $0.endTime > windowStart }
        guard let first = overlapping.first, let last = overlapping.last else {
            return nil
        }

        let location = first.characterRange.location
        let windowRange = NSRange(location: location, length: last.characterRange.upperBound - location)
        let snappedRange = snapToSentenceBoundaries(windowRange, in: model.attributedText.string)

        let raw = plainText(in: snappedRange, of: model.attributedText)
        let words = raw.split(whereSeparator: \.isWhitespace)
        guard words.count >= minimumWordCount else {
            return nil
        }
        return words.joined(separator: " ")
    }

    /// Expands `range` outward so it starts at the beginning of the sentence
    /// containing its first character and ends at the end of the sentence
    /// containing its last one. Never shrinks the range.
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

    /// The plain text within `range`, skipping speaker-name runs the transcript
    /// model interleaves between cues (marked with `.transcriptSpeaker`).
    private static func plainText(in range: NSRange, of attributedText: NSAttributedString) -> String {
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
        return parts.joined(separator: " ")
    }
}
