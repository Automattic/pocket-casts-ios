import AppIntents
import PocketCastsServer
import PocketCastsDataModel

enum EpisodeSearchIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noResults

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noResults:
            "No episodes found"
        }
    }
}

struct EpisodeSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Episodes"
    static var description = IntentDescription("Search for episodes")

    @Parameter(title: "Search Term")
    var searchTerm: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search episodes for \(\.$searchTerm)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[EpisodeSearchEntity]> {
        guard !searchTerm.isEmpty else {
            throw EpisodeSearchIntentError.noResults
        }

        let searchResults = try await EpisodeSearchTask().search(term: searchTerm)

        guard !searchResults.isEmpty else {
            throw EpisodeSearchIntentError.noResults
        }

        let episodeEntities = searchResults.map { EpisodeSearchEntity(searchResult: $0) }

        return .result(value: episodeEntities)
    }
}
