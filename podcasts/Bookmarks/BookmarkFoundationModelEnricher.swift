import Foundation
import FoundationModels
import NaturalLanguage

/// Generates a title and summary for a bookmark on-device using Apple's Foundation Models,
/// from the transcript text surrounding the bookmark's position.
///
/// On-device alternative to `CacheServerHandler.enrichBookmark(transcriptSnippet:)`.
@available(iOS 26.0, *)
final class BookmarkFoundationModelEnricher {
    struct Enrichment {
        let title: String
        let summary: String
    }

    enum EnrichmentError: Error {
        case modelUnavailable(SystemLanguageModel.Availability)
    }

    /// Whether the on-device model can be used (device eligible, Apple Intelligence enabled, model downloaded).
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    private static let instructions = """
        You create titles and summaries for podcast bookmarks. The user bookmarked a moment in a podcast \
        episode, and you are given the transcript of roughly one minute of audio centered on that moment. \
        The transcript may be preceded by PODCAST and EPISODE lines naming the show, and a \
        TRANSCRIPT_LANGUAGE line with the transcript's detected language code.

        Title requirements:
        - 3 to 6 words, never more than 8, naming the specific topic, person, claim, or advice being \
        discussed at the bookmarked moment (the midpoint of the transcript).
        - Sentence case, no surrounding quotes, no ending punctuation.
        - Never use generic titles like "Podcast discussion", meta phrases like "In this segment", or \
        the podcast or episode name.

        Example: for a transcript about salting chicken ahead of cooking so the salt has time to \
        penetrate, a good title is "Salt chicken hours before cooking", not "Cooking tips discussion".

        Also generate a one or two sentence summary of what is being discussed.

        Write the title and summary in TRANSCRIPT_LANGUAGE if provided, otherwise in the same language \
        as the transcript. Never translate into another language.
        """

    private var prewarmedSession: LanguageModelSession?

    /// Preloads model resources so an upcoming `enrich` call responds faster.
    /// Call when a bookmark is about to be created (e.g. when the bookmark UI is shown).
    func prewarm() {
        guard Self.isAvailable, prewarmedSession == nil else { return }

        let session = LanguageModelSession(instructions: Self.instructions)
        session.prewarm()
        prewarmedSession = session
    }

    func enrich(transcriptSnippet: String, podcastTitle: String? = nil, episodeTitle: String? = nil) async throws -> Enrichment {
        guard Self.isAvailable else {
            throw EnrichmentError.modelUnavailable(SystemLanguageModel.default.availability)
        }

        // Sessions are multi-turn and accumulate context, so each one is used for a single request.
        let session: LanguageModelSession
        if let prewarmedSession, !prewarmedSession.isResponding {
            session = prewarmedSession
            self.prewarmedSession = nil
        } else {
            session = LanguageModelSession(instructions: Self.instructions)
        }

        let prompt = Self.makePrompt(transcriptSnippet: transcriptSnippet, podcastTitle: podcastTitle, episodeTitle: episodeTitle)
        let response = try await session.respond(to: prompt, generating: GeneratedEnrichment.self)
        return Enrichment(title: response.content.title, summary: response.content.summary)
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

@available(iOS 26.0, *)
@Generable
private struct GeneratedEnrichment {
    @Guide(description: "A specific 3-6 word title for the bookmarked moment; sentence case, no quotes, no ending punctuation")
    let title: String

    @Guide(description: "A one or two sentence summary of what is being discussed")
    let summary: String
}
