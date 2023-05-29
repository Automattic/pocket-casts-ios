import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import Combine

struct PodcastsCarouselView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    /// Keep track of whether we're in landscape mode when on iPad
    @State private var isLandscape = false

    // Only show activity indicator when not searching for local podcasts
    private var shouldShowLoadingActivity: Bool {
        (searchResults.isSearchingForPodcasts && !searchResults.isShowingLocalResultsOnly) || (searchResults.isShowingLocalResultsOnly && searchResults.podcasts.isEmpty)
    }

    /// Calculate how many items we want to show in the carousel at a time
    /// On iPad we show more, and adjust for landscape orientation as well
    private var carouselItemsToDisplay: Int {
        guard UIDevice.current.isiPad() else {
            return Carousel.items
        }

        return isLandscape ? Carousel.iPadLandscapeItems : Carousel.iPadPortaitItems
    }

    private var podcastCellWidth: CGFloat {
        UIScreen.main.bounds.width / Double(carouselItemsToDisplay)
    }

    init() {
        // Get the initial landscape value from the scene since UIDevice may not have the value yet
        _isLandscape = State(initialValue: SceneHelper.connectedScene()?.interfaceOrientation.isLandscape ?? false)
    }

    var body: some View {
        Group {
            if shouldShowLoadingActivity {
                ZStack(alignment: .center) {
                    ProgressView()
                        .tint(AppTheme.loadingActivityColor().color)

                    ScrollView(.horizontal) {
                        if let podcast = PodcastFolderSearchResult(from: Podcast.previewPodcast()) {
                            LazyHStack(spacing: 0) {
                                PodcastResultCell(result: podcast)
                                    .padding(10)
                                    .frame(width: podcastCellWidth)
                                    .opacity(0)
                            }
                        }
                    }
                }
            } else if searchResults.podcasts.count > 0 {
                let fillerPodcast = Podcast.previewPodcast()

                // If needed, fill the results with filler podcasts to make sure the sizing and positioning is consistent
                let results: [PodcastFolderSearchResult] = {
                    let results = searchResults.podcasts
                    let minCount = carouselItemsToDisplay + 1 // + 1 to have a fake peeking item

                    guard results.count < minCount else {
                        return results
                    }

                    let diff = minCount - results.count

                    let filler = PodcastFolderSearchResult(from: fillerPodcast).flatMap {
                        Array(repeating: $0, count: diff)
                    } ?? []

                    return results + filler
                }()

                HorizontalCarousel(items: results) { podcast in
                    let isFiller = podcast.uuid == fillerPodcast.uuid

                    PodcastResultCell(result: podcast)
                        .opacity(isFiller ? 0 : 1)
                        .allowsHitTesting(isFiller ? false : true)
                }
                .carouselPeekAmount(.constant(20))
                .carouselItemSpacing(16)
                .carouselItemsToDisplay(carouselItemsToDisplay)

                // Apply an aspect ratio to the carousel to auto adjust the height
                // while maintaining the correct ratios for the items inside
                .aspectRatio(Double(carouselItemsToDisplay) - Carousel.aspectRatio, contentMode: .fit)
                .padding(.bottom, 10)
                .padding(.leading, 8)

                // Set the id of the carousel to make sure the we reset the position when the search changes
                .id(searchResults.podcasts.map { $0.id })

            } else if !searchResults.isShowingLocalResultsOnly {
                VStack(spacing: 2) {
                    Text(L10n.discoverNoPodcastsFound)
                        .font(style: .subheadline, weight: .medium)

                    Text(L10n.discoverNoPodcastsFoundMsg)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                        .multilineTextAlignment(.center)
                }
                .padding(.all, 10)
            }

            ThemedDivider()
                .padding(.leading, 8)
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
        .onReceive(UIDevice.orientationDidChangeNotification.publisher(), perform: { _ in
            isLandscape = UIDevice.current.orientation.isLandscape
        })
        .onAppear {
            guard UIDevice.current.isiPad() else { return }

            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        .onDisappear {
            guard UIDevice.current.isiPad() else { return }

            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    private enum Carousel {
        static let items = 2
        static let iPadPortaitItems = 4
        static let iPadLandscapeItems = 6

        static let aspectRatio = 0.2
    }
}

struct PodcastResultCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel

    let result: PodcastFolderSearchResult

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: {

                }) {
                    Group {
                        switch result.kind {
                        case .folder:
                            SearchFolderPreviewWrapper(uuid: result.uuid)
                                .aspectRatio(1, contentMode: .fit)
                                .modifier(NormalCoverShadow())
                        case .podcast:
                            PodcastImage(uuid: result.uuid, size: .grid)
                                .cornerRadius(8)
                                .shadow(radius: 6, x: 0, y: 2)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .gesture(TapGesture().onEnded { _ in
                        // This action is here instead of button action
                        // to avoid conflicts with the dismiss keyboard code
                        result.navigateTo()
                        searchHistory.add(podcast: result)
                        searchAnalyticsHelper.trackResultTapped(result)
                    })
                }

                if result.kind == .podcast {
                    RoundedSubscribeButtonView(podcastUuid: result.uuid)
                }
            }

            Button(action: { }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.titleToDisplay)
                        .lineLimit(1)
                        .font(style: .subheadline, weight: .medium)
                    Text(result.authorToDisplay)
                        .lineLimit(1)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                }
                .gesture(TapGesture().onEnded { _ in
                    // This action is here instead of button action
                    // to avoid conflicts with the dismiss keyboard code
                    result.navigateTo()
                    searchHistory.add(podcast: result)
                    searchAnalyticsHelper.trackResultTapped(result)
                })
            }
        }
    }
}

extension PodcastFolderSearchResult {
    func navigateTo() {
        switch kind {
        case .folder:
            NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: DataManager.sharedManager.findFolder(uuid: uuid) as Any])
        case .podcast:
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: self])
        }
    }
}
