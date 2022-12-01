import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListenedCategoriesStory: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    let identifier: String = "listened_categories"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: listenedCategories[0].mostListenedPodcast)

                VStack {
                    ZStack {
                        let size = geometry.size.width * 0.60

                        ForEach([2, 1, 0], id: \.self) {
                            podcastCover($0)
                                .frame(width: size, height: size)
                                .modifier(PodcastCoverPerspective())
                                .padding(.top, (size * CGFloat($0) * 0.3))
                        }
                    }

                    VStack {
                        StoryLabel(L10n.eoyStoryListenedToCategories("\n\(listenedCategories.count)"), for: .title)
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)

                        StoryLabel(L10n.eoyStoryListenedToCategoriesSubtitle, for: .subtitle)
                            .frame(maxHeight: geometry.size.height * 0.07)
                            .minimumScaleFactor(0.01)
                            .opacity(renderForSharing ? 0.0 : 0.8)
                    }
                }
                .padding(.top, -(geometry.size.height * 0.15))
            }
        }
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        let podcast = listenedCategories[safe: index]?.mostListenedPodcast ?? listenedCategories[0].mostListenedPodcast
        PodcastCover(podcastUuid: podcast.uuid, big: true)
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryListenedToCategoriesShareText(listenedCategories.count))
        ]
    }
}

struct ListenedCategoriesStory_Previews: PreviewProvider {
    static var previews: some View {
        ListenedCategoriesStory(listenedCategories: [ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Seila", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300)])
    }
}
