import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum BookmarkTitleGenerator {
    private static let maxTitleLength = Constants.Values.bookmarkMaxTitleLength
    private static let heuristicWordLimit = 8

    static func generateTitle(from text: String) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if let aiTitle = await generateWithAppleIntelligence(text: text) {
                return aiTitle
            }
        }
        #endif

        return heuristicTitle(from: text)
    }

    // MARK: - Apple Intelligence

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private static func generateWithAppleIntelligence(text: String) async -> String? {
        let model = SystemLanguageModel.default
        guard model.availability == .available else { return nil }

        do {
            let session = LanguageModelSession(instructions: """
                Summarize this podcast excerpt as a short descriptive title (3-8 words). \
                Describe the topic, do NOT quote the text verbatim. \
                Output ONLY the title text, nothing else. No quotes, no punctuation at the end.
                """)
            let response = try await session.respond(to: text)
            let title = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            return String(title.prefix(maxTitleLength))
        } catch {
            return nil
        }
    }
    #endif

    // MARK: - Heuristic Fallback

    static func heuristicTitle(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return L10n.bookmarkDefaultTitle }

        let words = cleaned.split(separator: " ", maxSplits: heuristicWordLimit + 1, omittingEmptySubsequences: true)

        if words.count <= heuristicWordLimit {
            let joined = words.joined(separator: " ")
            return joined.count <= maxTitleLength ? joined : truncateAtWordBoundary(joined)
        }

        let snippet = words.prefix(heuristicWordLimit).joined(separator: " ")
        return truncateAtWordBoundary(snippet + "…")
    }

    private static func truncateAtWordBoundary(_ text: String) -> String {
        guard text.count > maxTitleLength else { return text }
        let truncated = String(text.prefix(maxTitleLength - 1))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[truncated.startIndex..<lastSpace]) + "…"
        }
        return truncated + "…"
    }
}
