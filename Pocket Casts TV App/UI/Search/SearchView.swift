import SwiftUI

// MARK: - View Model
@MainActor
@Observable
class SearchViewModel {

    enum SearchScope: String, CaseIterable {
        case all = "All"
        case podcasts = "Podcasts"
        case episodes = "Episodes"
    }

    var scope: SearchScope = .all

    enum State {
        case query
        case searching
        case results
        case error(Error)
        case empty
    }

    var state: State = .query

    var results: [MockPodcast] = []

    var searchHistory: [String] = ["Conan"]

    var autoCompleteSuggestions: [String] = []

    private var searchTask: Task<Void, Never>?


    func search(query: String) {
        // Cancel any previous task
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard !Task.isCancelled else { return }

            state = .searching

            do {
                let podcasts = try await fetchPodcasts(query: query)
                guard !Task.isCancelled else { return }
                results = podcasts
                state = .results
            } catch {
                state  = .error(error)
            }
        }
    }

    func autoComplete(query: String) {
        autoCompleteSuggestions = MockData.makePodcasts().filter() { podcast in
            podcast.title.localizedCaseInsensitiveContains(query)
        }.map {
            $0.title
        }
    }

    private func fetchPodcasts(query: String) async throws -> [MockPodcast] {
        // Replace with your actual API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.makePodcasts().filter() { podcast in
            podcast.title.localizedCaseInsensitiveContains(query)
        }
    }
}

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                if searchText.isEmpty {
                    EmptyDataView(title: "Search for something", subtitle: "", actionTitle: nil, action: nil)
                } else {
                    switch viewModel.state {
                    case .searching:
                        ProgressView("Searching...")
                    case .empty:
                        ContentUnavailableView.search(text: searchText)
                    case .results:
                        podcastGrid
                    case .error(let error):
                        Text("Search failed: \(error.localizedDescription)")
                    case .query:
                        Text("Type something...")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Podcasts, shows, authors")
            .searchScopes($viewModel.scope) {
                ForEach(SearchViewModel.SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .searchSuggestions {
                if searchText.isEmpty {
                    Section("Recent") {
                        ForEach(viewModel.searchHistory, id: \.self) { search in
                            Label(search, systemImage: "clock")
                                .searchCompletion(search)
                        }
                    }
                } else {
                    // Live suggestions based on query
                    ForEach(viewModel.autoCompleteSuggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .searchCompletion(suggestion)
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.search(query: newValue)
                viewModel.autoComplete(query: newValue)
            }
        }
    }

    enum Layout {
        static let gridSize = CGFloat(250)
    }

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    var podcastGrid: some View {
        ScrollView {
            LazyVGrid(columns: items, spacing: 48, content: {
                ForEach(viewModel.results) { podcast in
                    NavigationLink(value: podcast) {
                        Image(podcast.image)
                            .resizable()
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                    }
                    .buttonStyle(.card)
                }
            })
            .navigationDestination(for: MockPodcast.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
            }
        }
    }
}
