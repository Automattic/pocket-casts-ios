import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct OnboardingRecommendationsView: View {

    let coordinator: LoginCoordinator

    @State var categories: [DiscoverCategory] = []
    @State var layout: DiscoverLayout?
    @State var categoryPodcasts: [Int: [DiscoverPodcast]] = [:]
    @State var showingImport = false

    @EnvironmentObject var theme: Theme
    @State var searchTerm: String = ""

    @State var searchResults = [PodcastFolderSearchResult]()
    @State var searchTask: Task<Void, Never>?

    var body: some View {
        Group {
            if layout != nil {
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        VStack(spacing: 16) {
                            header()
                            searchBar()
                            if searchTerm.isEmpty {
                                ForEach(categories, id: \.id) { category in
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(category.name ?? "Unknown")
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(theme.primaryText01)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 20)
                                        DiscoverPodcastsGridView(
                                            category: category,
                                            podcasts: categoryPodcasts[category.id ?? 0] ?? []
                                        )
                                        .frame(minHeight: (DiscoverPodcastsGridView.Constants.itemHeight * 2) + DiscoverPodcastsGridView.Constants.gridSpacing + 4)
                                    }
                                }
                            } else {
                                if #available(iOS 17.0, *) {
                                    podcastList()
                                        .onChange(of: searchTerm) { oldValue, newValue in
                                            performSearch(term: newValue)
                                        }
                                } else {
                                    podcastList()
                                        .onChange(of: searchTerm) { newValue in
                                            performSearch(term: newValue)
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                    .fadeGradient(bottomOffset: 50)

                    VStack {
                        Button(action: {
                            OnboardingFlow.shared.track(.recommendationsDismissed)
                            coordinator.recommendationsContinueTapped()
                        }) {
                            Text(L10n.continue)
                                .textStyle(RoundedButton())
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        .padding(.bottom)
                    }
                    .background(theme.primaryInteractive02)
                    .background(.ultraThinMaterial)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primaryIcon01))
                    .task {
                        let page = await DiscoverServerHandler.shared.discoverPage()
                        guard let layout = page.0 else {
                            return
                        }

                        let categoriesItem = layout.layout?.first { item in
                            item.type == "categories"
                        }
                        guard let categoriesItem else {
                            return
                        }
                        categories = await DiscoverServerHandler.shared.discoverCategories(source: categoriesItem.source ?? "", authenticated: categoriesItem.isAuthenticated)
                        self.layout = layout

                        OnboardingFlow.shared.track(.recommendationsShown)

                        await loadCategoryPodcasts(layout: layout)
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.import) {
                    showingImport = true
                }
                .tint(theme.primaryInteractive01)
            }
        }
        .background(theme.primaryInteractive02)
        .environmentObject(SearchAnalyticsHelper(source: .recommendations))
    }

    private func performSearch(term: String) {
        searchTask?.cancel()

        guard !term.isEmpty else {
            searchResults = []
            return
        }

        OnboardingFlow.shared.track(.recommendationsSearchTapped)

        searchTask = Task {
            do {
                let podcastSearch = PodcastSearchTask()
                let results = try await podcastSearch.search(term: term)

                if !Task.isCancelled {
                    await MainActor.run {
                        searchResults = results
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        searchResults = []
                    }
                }
            }
        }
    }

    private func regionCode(for layout: DiscoverLayout) -> String {
        let currentRegionCode = Settings.discoverRegion(discoverLayout: layout)
        let serverRegion = layout.regions?[currentRegionCode]?.code ?? "us"
        return serverRegion
    }

    private func loadCategoryPodcasts(layout: DiscoverLayout) async {
        let regionCode = regionCode(for: layout)

        await withTaskGroup(of: Void.self) { group in
            for category in categories {
                group.addTask {
                    let source = category.source?.replacingOccurrences(of: layout.regionCodeToken, with: regionCode)
                    let podcasts = await DiscoverServerHandler.shared.discoverCategoryDetails(source: source ?? "", authenticated: false)?.podcasts ?? []

                    await MainActor.run {
                        self.categoryPodcasts[category.id ?? 0] = podcasts
                    }
                }
            }
        }
    }


    @ViewBuilder func header() -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .center, spacing: 16) {
                Text(L10n.onboardingRecommendationsTitle)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText01)
                Text(L10n.onboardingRecommendationsSubtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.primaryText02)
            }
            .padding(.horizontal, 30)
        }
        .padding(.top, 20)
        .sheet(isPresented: $showingImport) {
            NavigationStack {
                ImportLandingView(viewModel: ImportViewModel())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(L10n.accessibilityDismiss) {
                                showingImport = false
                                OnboardingFlow.shared.track(.onboardingImportDismissed)
                            }
                            .foregroundColor(theme.primaryInteractive01)
                        }
                    }
                    .onAppear {
                        OnboardingFlow.shared.track(.onboardingImportShown)
                    }
            }
            .environmentObject(theme)
        }
    }

    @ViewBuilder func searchBar() -> some View {
        PCSearchView(searchTerm: $searchTerm, shouldShowCancelButton: true)
            .frame(height: PCSearchView.defaultHeight)
    }

    @ViewBuilder func podcastList() -> some View {
        LazyVStack(spacing: 0) {
            ForEach(searchResults) { podcast in
                SearchResultCell(episode: nil, result: podcast, played: false)
            }
        }
        .environmentObject(SearchHistoryModel.shared)
        .padding(.horizontal, 20)
    }
}

#Preview("Live") {
    OnboardingRecommendationsView(coordinator: LoginCoordinator())
        .environmentObject(Theme(previewTheme: .extraDark))
}
