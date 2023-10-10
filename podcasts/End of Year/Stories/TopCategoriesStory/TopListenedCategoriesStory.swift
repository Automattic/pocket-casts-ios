import SwiftUI
import PocketCastsDataModel

struct TopListenedCategoriesStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "top_categories"

    let listenedCategories: [ListenedCategory]

    let contrastColor: CategoriesContrastingColors

    init(listenedCategories: [ListenedCategory]) {
        self.listenedCategories = listenedCategories
        self.contrastColor = CategoriesContrastingColors(podcast: listenedCategories.reversed()[0].mostListenedPodcast)
    }

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                let headerSpacing = geometry.size.height * 0.054

                StoryLabel(L10n.eoyStoryTopCategories, for: .title2)
                    .opacity(0.8)

                HStack(alignment: .bottom, spacing: 25) {
                    ForEach([1, 0, 2], id: \.self) {
                        pillar($0, size: geometry.size)
                    }
                }.padding(.top, headerSpacing)
            }.background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient()
                    .offset(x: -geometry.size.width * 0.4, y: -geometry.size.height * 0.7)
                }
            )
        }
    }

    @ViewBuilder
    func pillar(_ index: Int, size: CGSize) -> some View {
        let heights = [0.32882883, 0.29279279, 0.22222222]

        if let listenedCategory = listenedCategories[safe: index] {
            CategoryPillar(color: contrastColor.tintColor,
                           text: "\(index + 1)",
                           title: listenedCategory.categoryTitle.localized,
                           subtitle: listenedCategory.totalPlayedTime.storyTimeDescriptionForPillars,
                           height: size.height * heights[index])
                .padding(.bottom, index == 0 ? 70 : 0)
        } else {
            CategoryPillar(color: contrastColor.tintColor,
                           text: "",
                           title: "",
                           subtitle: "",
                           height: (size.height * heights[0])).opacity(0)
        }
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
            StoryShareableText(L10n.eoyStoryTopCategoriesShareText)
        ]
    }
}

#if DEBUG
struct TopListenedCategories_Previews: PreviewProvider {
    static var previews: some View {
        TopListenedCategoriesStory(listenedCategories: [
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Test category big title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Small title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Category", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300)
        ])
    }
}
#endif
