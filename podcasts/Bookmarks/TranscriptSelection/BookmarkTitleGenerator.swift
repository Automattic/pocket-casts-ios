import Foundation
import NaturalLanguage
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

        if let nlpTitle = nlpTitle(from: text) {
            return nlpTitle
        }

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

    // MARK: - NLP Keyword Extraction

    static func nlpTitle(from text: String) -> String? {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        var namedEntities: [String] = []
        let nameTagger = NLTagger(tagSchemes: [.nameType])
        nameTagger.string = cleaned
        let nameOptions: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let entityTags: [NLTag] = [.personalName, .placeName, .organizationName]

        nameTagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex, unit: .word, scheme: .nameType, options: nameOptions) { tag, tokenRange in
            if let tag, entityTags.contains(tag) {
                namedEntities.append(String(cleaned[tokenRange]))
            }
            return true
        }

        var nouns: [String] = []
        let posTagger = NLTagger(tagSchemes: [.lexicalClass])
        posTagger.string = cleaned
        let posOptions: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        posTagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex, unit: .word, scheme: .lexicalClass, options: posOptions) { tag, tokenRange in
            if tag == .noun {
                let word = String(cleaned[tokenRange])
                if !namedEntities.contains(where: { $0.contains(word) }) {
                    nouns.append(word)
                }
            }
            return true
        }

        var seen = Set<String>()
        let uniqueNouns = nouns.filter { seen.insert($0.lowercased()).inserted }
        let keywords = namedEntities + Array(uniqueNouns.prefix(4))
        guard !keywords.isEmpty else { return nil }

        let title = keywords.prefix(5).joined(separator: ", ")
        guard !title.isEmpty else { return nil }

        return title.count <= maxTitleLength ? title : truncateAtWordBoundary(title)
    }

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
