import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum BookmarkTitleGenerator {
    private static let maxTitleLength = Constants.Values.bookmarkMaxTitleLength

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
                Generate a short title (under 8 words) that captures the key topic of this podcast excerpt. \
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

        let sentenceEnd = cleaned.rangeOfCharacter(from: CharacterSet(charactersIn: ".!?"))
        let firstSentence: String
        if let end = sentenceEnd {
            firstSentence = String(cleaned[cleaned.startIndex...end.lowerBound])
        } else {
            firstSentence = cleaned
        }

        if firstSentence.count <= maxTitleLength {
            return firstSentence
        }

        let truncated = String(firstSentence.prefix(maxTitleLength - 1))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[truncated.startIndex..<lastSpace]) + "…"
        }
        return truncated + "…"
    }
}
