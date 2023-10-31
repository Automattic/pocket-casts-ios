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
            PodcastCoverContainer(geometry: geometry) {
                PodcastStackView(podcasts: listenedCategories.map { $0.mostListenedPodcast }, geometry: geometry)

                StoryLabelContainer(geometry: geometry) {
                    let categories = L10n.eoyStoryListenedToCategoriesText(listenedCategories.count)
                    if NSLocale.isCurrentLanguageEnglish {
                        StoryLabel(L10n.eoyStoryListenedToCategoriesHighlighted("\n\(categories)\n"),
                                   highlighting: [categories],
                                   for: .title)
                    } else {
                        StoryLabel(L10n.eoyStoryListenedToCategories("\n\(listenedCategories.count)"),
                                   for: .title)
                    }
                    StoryLabel(L10n.eoyStoryListenedToCategoriesSubtitle, for: .subtitle)
                        .opacity(renderForSharing ? 0.0 : 0.8)
                }
            }
        }.background(DynamicBackgroundView(podcast: listenedCategories[0].mostListenedPodcast))
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
        ListenedCategoriesStory(listenedCategories: [ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Seila", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300, numberOfEpisodes: 5)])
    }
}
