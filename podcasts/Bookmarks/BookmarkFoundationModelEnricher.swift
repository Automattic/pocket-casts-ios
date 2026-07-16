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
        episode, and you are given the transcript of roughly one minute of audio around that moment, \
        optionally preceded by a TRANSCRIPT_LANGUAGE line with its detected language code. \
        Generate a short, specific title of at most 8 words and a one or two sentence summary of what is \
        being discussed. Write the title and summary in TRANSCRIPT_LANGUAGE if provided, otherwise in the \
        same language as the transcript. Never translate into another language.
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

    func enrich(transcriptSnippet: String) async throws -> Enrichment {
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

        let prompt = Self.makePrompt(transcriptSnippet: transcriptSnippet)
        let response = try await session.respond(to: prompt, generating: GeneratedEnrichment.self)
        return Enrichment(title: response.content.title, summary: response.content.summary)
    }

    /// Prefixes the transcript with its detected language so the model responds in the
    /// transcript's language instead of defaulting to English.
    private static func makePrompt(transcriptSnippet: String) -> String {
        guard let language = detectLanguage(from: transcriptSnippet) else {
            return transcriptSnippet
        }
        return """
            TRANSCRIPT_LANGUAGE: \(language)

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
    @Guide(description: "A short, specific title for the bookmarked moment, at most 8 words")
    let title: String

    @Guide(description: "A one or two sentence summary of what is being discussed")
    let summary: String
}
