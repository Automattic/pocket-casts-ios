import Foundation
import NaturalLanguage
import PocketCastsDataModel
import PocketCastsUtils

/// The transcript passage captured for a bookmark, kept alongside the transcript it was
/// taken from so it can be re-selected later.
struct BookmarkTranscriptSnippet {
    let transcript: TranscriptModel
    var range: NSRange

    /// The reference-timeline position the snippet was centered on; nil for a snippet
    /// re-located from a stored passage, which isn't resolved against a time.
    var referenceTime: TimeInterval?

    var text: String {
        BookmarkTranscriptSnippetExtractor.text(in: range, of: transcript.attributedText)
    }
}

/// Why no transcript passage could be captured for a bookmark.
enum BookmarkPassageFailureReason: Error {
    /// The episode has no transcript, or fetching it failed
    case transcriptUnavailable
    /// The transcript isn't machine generated, or its fingerprint didn't confidently
    /// match, so the bookmark's time can't be resolved onto the transcript's timeline
    case notFingerprinted
    /// The transcript has nothing covering the bookmarked moment
    case noTranscriptAtPosition
    /// Too few words around the moment to write a title from
    case passageTooShort
}

/// Extracts the transcript text surrounding a bookmark's position, used as the
/// input for generating a bookmark title.
///
/// Limited to fingerprinted transcripts. Generated transcripts are timed against a
/// reference copy of the episode audio that dynamic ads shift away from, so the
/// bookmark's playback time has to be resolved to the reference timeline (see
/// `docs/transcripts.md`) before it points at the right words. Anything else — an
/// externally supplied transcript, or a fingerprint that doesn't confidently match —
/// yields no snippet rather than one taken from the raw playback time.
struct BookmarkTranscriptSnippetExtractor {

    /// The window reaches further back than forward: by the time a user bookmarks
    /// a moment, that moment is already behind the playhead.
    static let backwardWindowSeconds: TimeInterval = 25
    static let forwardWindowSeconds: TimeInterval = 5

    /// Snippets with fewer words than this carry too little signal to generate a meaningful title from
    static let minimumWordCount = 10

    /// The passage surrounding the given playback time, or why one couldn't be found.
    ///
    /// - Parameter referenceTime: The bookmark's already-resolved reference time, if any.
    ///   It's preferred over resolving again, both to save the work and because the
    ///   original capture had the warmest mapping.
    func capture(forTime time: TimeInterval, referenceTime: TimeInterval?, episode: BaseEpisode) async -> Result<BookmarkTranscriptSnippet, BookmarkPassageFailureReason> {
        let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: episode.parentIdentifier())
        guard let model = try? await transcriptManager.loadTranscript() else {
            return .failure(.transcriptUnavailable)
        }

        // Only generated transcripts have a reference fingerprint to re-anchor against, and
        // without a confident match there's no telling how far dynamic ads have pushed the
        // playback time from the timeline the transcript is cued against. Either way, capture
        // nothing rather than a passage from somewhere else in the episode.
        guard transcriptManager.isDisplayingGeneratedTranscript, FeatureFlag.syncedTranscripts.enabled else {
            return .failure(.notFingerprinted)
        }

        var resolved = referenceTime
        if resolved == nil {
            resolved = await FingerprintTimingManager.shared.resolveReferenceTime(forPlaybackTime: time, episode: episode)
        }
        guard let resolved else {
            return .failure(.notFingerprinted)
        }

        return Self.extractSnippet(from: model, at: resolved).map {
            var snippet = $0
            snippet.referenceTime = resolved
            return snippet
        }
    }

    func snippet(forPassage passage: String, at location: Int?, episode: BaseEpisode) async -> BookmarkTranscriptSnippet? {
        let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: episode.parentIdentifier())
        guard let model = try? await transcriptManager.loadTranscript(),
              let range = Self.passageRange(for: passage, at: location, in: model.attributedText) else {
            return nil
        }

        return BookmarkTranscriptSnippet(transcript: model, range: range)
    }

    static func extractSnippet(from model: TranscriptModel, at time: TimeInterval) -> Result<BookmarkTranscriptSnippet, BookmarkPassageFailureReason> {
        let windowStart = max(0, time - backwardWindowSeconds)
        let windowEnd = time + forwardWindowSeconds

        let overlapping = model.cues.filter { $0.startTime < windowEnd && $0.endTime > windowStart }
        guard let first = overlapping.first, let last = overlapping.last else {
            return .failure(.noTranscriptAtPosition)
        }

        let location = first.characterRange.location
        let windowRange = NSRange(location: location, length: last.characterRange.upperBound - location)
        let snappedRange = snapToSentenceBoundaries(windowRange, in: model.attributedText.string)

        let snippet = BookmarkTranscriptSnippet(transcript: model, range: snappedRange)
        guard snippet.text.split(whereSeparator: \.isWhitespace).count >= minimumWordCount else {
            return .failure(.passageTooShort)
        }
        return .success(snippet)
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

    // MARK: - Locating a passage

    /// Finds the range to highlight for a bookmark's captured passage within a transcript.
    ///
    /// The passage text is the source of truth; `location` only disambiguates when the same
    /// passage appears more than once. So the captured location is tried first, and only when
    /// the text there no longer lines up does it fall back to the first match of the passage
    /// text anywhere in the transcript.
    ///
    /// - Parameter location: The passage's captured start within `attributedText`, or `nil`
    ///   for bookmarks made before the location was recorded.
    static func passageRange(for passage: String, at location: Int?, in attributedText: NSAttributedString) -> NSRange? {
        // The transcript side of the match collapses whitespace, so the passage collapses
        // the same way — lining up passages stored flattened by earlier versions and
        // passages stored with their line breaks alike
        let passage = passage.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !passage.isEmpty else { return nil }

        // Location first: is the passage still exactly where it was captured?
        if let location {
            let suffix = cleaned(attributedText, from: location)
            if suffix.text.hasPrefix(passage),
               let end = suffix.text.index(suffix.text.startIndex, offsetBy: passage.count, limitedBy: suffix.text.endIndex) {
                return suffix.transcriptRange(for: suffix.text.startIndex..<end)
            }
        }

        // Otherwise search the whole transcript, taking the first occurrence
        let full = cleaned(attributedText, from: 0)
        guard let match = full.text.range(of: passage) else { return nil }
        return full.transcriptRange(for: match)
    }

    /// The transcript's text collapsed the same way a passage is, paired with a map back to
    /// the character positions each piece came from
    private struct CleanedText {
        let text: String
        /// Start position in the transcript of each character in `text`
        let starts: [Int]
        /// Position in the transcript just past each character in `text`
        let ends: [Int]

        /// Maps a range found within `text` back to the transcript's character positions
        func transcriptRange(for cleanedRange: Range<String.Index>) -> NSRange? {
            let lower = text.distance(from: text.startIndex, to: cleanedRange.lowerBound)
            let upper = text.distance(from: text.startIndex, to: cleanedRange.upperBound)
            guard lower >= 0, upper > lower, upper <= starts.count else { return nil }
            return NSRange(location: starts[lower], length: ends[upper - 1] - starts[lower])
        }
    }

    /// Cleans the transcript from `startLocation` onward the same way `text(in:)` cleans a
    /// passage — skipping speaker runs, collapsing whitespace — while recording where each
    /// surviving character came from, so a match can be mapped back to the transcript.
    private static func cleaned(_ attributedText: NSAttributedString, from startLocation: Int) -> CleanedText {
        let string = attributedText.string as NSString
        let total = string.length
        let start = min(max(startLocation, 0), total)
        guard start < total else { return CleanedText(text: "", starts: [], ends: []) }

        let scanRange = NSRange(location: start, length: total - start)

        var text = ""
        var starts = [Int]()
        var ends = [Int]()
        // A run of whitespace (real or the boundary between two cue parts) collapses to a
        // single space, dropped entirely at the start or end
        var pendingSpace: (start: Int, end: Int)?
        var isFirstPart = true

        attributedText.enumerateAttribute(.transcriptSpeaker, in: scanRange, options: []) { value, subrange, _ in
            guard value == nil else { return }

            if !isFirstPart {
                pendingSpace = pendingSpace ?? (subrange.location, subrange.location)
            }
            isFirstPart = false

            string.enumerateSubstrings(in: subrange, options: .byComposedCharacterSequences) { substring, characterRange, _, _ in
                guard let substring else { return }

                if substring.allSatisfy(\.isWhitespace) {
                    if !text.isEmpty {
                        pendingSpace = pendingSpace ?? (characterRange.location, characterRange.location + characterRange.length)
                    }
                    return
                }

                if let space = pendingSpace {
                    text.append(" ")
                    starts.append(space.start)
                    ends.append(space.end)
                    pendingSpace = nil
                }

                text.append(substring)
                starts.append(characterRange.location)
                ends.append(characterRange.location + characterRange.length)
            }
        }

        return CleanedText(text: text, starts: starts, ends: ends)
    }

    /// The plain text within `range`, skipping the speaker-name runs interleaved between
    /// cues while keeping the transcript's line breaks, so a stored passage reads with
    /// the same paragraphs the transcript shows
    static func text(in range: NSRange, of attributedText: NSAttributedString) -> String {
        let clamped = NSIntersectionRange(range, NSRange(location: 0, length: attributedText.length))
        guard clamped.length > 0 else {
            return ""
        }

        let string = attributedText.string as NSString
        var text = ""
        // A whitespace run collapses to a single newline when it contains one, a single
        // space otherwise; dropped entirely at either edge
        var pendingSeparator: String?

        attributedText.enumerateAttribute(.transcriptSpeaker, in: clamped, options: []) { value, subrange, _ in
            guard value == nil else {
                // Speaker names sit on their own line, so skipping one leaves a line break
                if !text.isEmpty {
                    pendingSeparator = "\n"
                }
                return
            }

            string.enumerateSubstrings(in: subrange, options: .byComposedCharacterSequences) { substring, _, _, _ in
                guard let substring else { return }

                if substring.allSatisfy(\.isWhitespace) {
                    if !text.isEmpty {
                        pendingSeparator = substring.contains(where: \.isNewline) ? "\n" : (pendingSeparator ?? " ")
                    }
                    return
                }

                if let separator = pendingSeparator {
                    text.append(separator)
                    pendingSeparator = nil
                }
                text.append(substring)
            }
        }

        return text
    }
}
