import Foundation
import FoundationModels

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
        episode, and you are given the transcript of roughly one minute of audio around that moment. \
        Generate a short, specific title of at most 8 words and a one or two sentence summary of what is \
        being discussed. Respond in the same language as the transcript.
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

        let response = try await session.respond(to: transcriptSnippet, generating: GeneratedEnrichment.self)
        return Enrichment(title: response.content.title, summary: response.content.summary)
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
