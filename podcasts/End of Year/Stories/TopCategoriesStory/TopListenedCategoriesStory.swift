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
                StoryLabelContainer(geometry: geometry) {
                    let mostListenedCategory = listenedCategories.first?.categoryTitle ?? ""
                    let listenedTime = listenedCategories.first?.totalPlayedTime.storyTimeDescription ?? ""
                    let listenedEpisodes = "\(listenedCategories.first?.numberOfEpisodes ?? 0)"
                    StoryLabel(L10n.eoyStoryTopCategoriesTitle(mostListenedCategory), for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyStoryTopCategoriesSubtitle(listenedEpisodes, listenedTime), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                let headerSpacing = geometry.size.height * 0.054

                VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                    ForEach(0...min(listenedCategories.count, 3), id: \.self) { index in
                        HStack(spacing: 24) {
                            Text("\(index + 1)")
                                .font(.custom("DM Sans", size: geometry.size.height * 0.025))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "8F97A4"))
                                .offset(y: -5)
                                .frame(width: geometry.size.width * 0.03)

                            VStack(alignment: .leading) {
                                if index == 0 {
                                    Text("\(listenedCategories[safe: index]?.categoryTitle ?? "")")
                                        .font(.custom("DM Sans", size: geometry.size.height * 0.06))
                                        .fontWeight(.medium)
                                        .scaledToFill()
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                        .foregroundStyle(
                                            LinearGradient(
                                            stops: [
                                            Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
                                            Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
                                            Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
                                            Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.74),
                                            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
                                            ],
                                            startPoint: UnitPoint(x: -0.3, y: -0.27),
                                            endPoint: UnitPoint(x: 1.5, y: 1.19)
                                            )
                                        )

                                    Text("\(listenedCategories[safe: index]?.totalPlayedTime.storyTimeDescription ?? "")")
                                        .font(.custom("DM Sans", size: geometry.size.height * 0.018))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: "FBFBFC"))
                                } else {
                                    Text("\(listenedCategories[safe: index]?.categoryTitle ?? "")")
                                        .font(.custom("DM Sans", size: geometry.size.height * 0.06))
                                        .fontWeight(.medium)
                                        .scaledToFill()
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                        .foregroundColor(Color(hex: "686C74"))

                                    Text("\(listenedCategories[safe: index]?.totalPlayedTime.storyTimeDescription ?? "")")
                                        .font(.custom("DM Sans", size: geometry.size.height * 0.018))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: "686C74"))
                                }
                            }

                            Spacer()
                        }
                    }
                }
                .padding([.leading, .trailing], 35)
                .padding(.top, headerSpacing)
            }.background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient()
                    .offset(x: -geometry.size.width * 0.4, y: -geometry.size.height * 0.7)
                }
                    .clipped()
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
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Test category big title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300, numberOfEpisodes: 1),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Small title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300, numberOfEpisodes: 2),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Tech", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300, numberOfEpisodes: 3),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Art", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 80000, numberOfEpisodes: 4)
        ])
    }
}
#endif
