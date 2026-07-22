import Foundation
import FoundationModels
import NaturalLanguage

#if os(iOS)

/// Generates a title for a bookmark on-device using Apple's Foundation Models,
/// from the transcript text surrounding the bookmark's position.
///
/// On-device alternative to `CacheServerHandler.enrichBookmark(transcriptSnippet:)`.
@available(iOS 26.0, *)
final class BookmarkFoundationModelEnricher {
    enum EnrichmentError: Error {
        case modelUnavailable(SystemLanguageModel.Availability)
        case unexpectedResponse
    }

    /// Permissive guardrails keep transcripts covering heavy podcast topics (true crime,
    /// health, violent news) from being rejected with a `guardrailViolation`. They only
    /// apply to plain `String` generation — with guided generation (`@Generable`) the
    /// default guardrails still run — which is why this class generates the title as raw text.
    private static let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

    /// Whether the on-device model can be used (device eligible, Apple Intelligence enabled, model downloaded).
    static var isAvailable: Bool {
        model.isAvailable
    }

    /// Responses longer than this are treated as the model explaining or refusing
    /// rather than titling, and rejected. The instructions ask for around 3 to 6 words.
    private static let maxTitleWordCount = 12

    private static let instructions = """
        You are helping a Pocket Casts user remember a moment they bookmarked in a podcast episode.
        Generate a title for the bookmark from the transcript of roughly one minute \
        of audio centered on the bookmarked moment.

        **Prompt Parameters**
        - PODCAST: name of the show, when available (context only — never repeat it in the title)
        - EPISODE: name of the episode, when available (context only — never repeat it in the title)
        - TRANSCRIPT_LANGUAGE: the detected language code of TRANSCRIPT (e.g., "en", "es", "ja") when available
        - TRANSCRIPT: the transcript text surrounding the bookmarked moment

        **Title Requirements**
        - Aim for around 3 to 6 words, naming the specific topic, person, claim, or advice being \
        discussed at the bookmarked moment (the midpoint of TRANSCRIPT).
        - Sentence case, no surrounding quotes, no ending punctuation.
        - Never use generic titles like "Podcast discussion" or meta phrases like "In this segment".
        - Example: for a transcript about salting chicken ahead of cooking so the salt has time to \
        penetrate, a good title is "Salt chicken hours before cooking", not "Cooking tips discussion".

        **Output Format**
        Respond with ONLY the title text — no label, no quotes, no explanation.

        **CRITICAL Requirement**
        ⚠️ LANGUAGE: Generate the title in the language specified by the \
        TRANSCRIPT_LANGUAGE code if provided, otherwise match TRANSCRIPT language exactly. \
        NO translation. NO defaulting to English. Match input language EXACTLY.
        """

    private var prewarmedSession: LanguageModelSession?

    /// Preloads model resources so an upcoming `generateTitle` call responds faster.
    func prewarm() {
        guard Self.isAvailable, prewarmedSession == nil else { return }

        let session = Self.makeSession()
        session.prewarm()
        prewarmedSession = session
    }

    func generateTitle(transcriptSnippet: String, podcastTitle: String? = nil, episodeTitle: String? = nil) async throws -> String {
        guard Self.isAvailable else {
            throw EnrichmentError.modelUnavailable(Self.model.availability)
        }

        // Sessions are multi-turn and accumulate context, so each one is used for a single request.
        let session: LanguageModelSession
        if let prewarmedSession, !prewarmedSession.isResponding {
            session = prewarmedSession
            self.prewarmedSession = nil
        } else {
            session = Self.makeSession()
        }

        let prompt = Self.makePrompt(transcriptSnippet: transcriptSnippet, podcastTitle: podcastTitle, episodeTitle: episodeTitle)
        let response = try await session.respond(to: prompt)

        let title = response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'’"))
        guard !title.isEmpty, title.split(whereSeparator: \.isWhitespace).count <= Self.maxTitleWordCount else {
            throw EnrichmentError.unexpectedResponse
        }
        return title
    }

    private static func makeSession() -> LanguageModelSession {
        LanguageModelSession(model: model, instructions: instructions)
    }

    /// Prefixes the transcript with the show names (context the title shouldn't repeat) and its
    /// detected language, so the model responds in the transcript's language instead of defaulting
    /// to English.
    private static func makePrompt(transcriptSnippet: String, podcastTitle: String?, episodeTitle: String?) -> String {
        var contextLines = [String]()
        if let podcastTitle {
            contextLines.append("PODCAST: \(podcastTitle)")
        }
        if let episodeTitle {
            contextLines.append("EPISODE: \(episodeTitle)")
        }
        if let language = detectLanguage(from: transcriptSnippet) {
            contextLines.append("TRANSCRIPT_LANGUAGE: \(language)")
        }

        guard !contextLines.isEmpty else {
            return transcriptSnippet
        }
        return """
            \(contextLines.joined(separator: "\n"))

            TRANSCRIPT:
            \(transcriptSnippet)
            """
    }

    /// Detects the dominant language of the given text (e.g. "en", "es", "ja").
    private static func detectLanguage(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}

#endif
