import SwiftUI
import PocketCastsDataModel

struct TopListenedCategoriesStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "top_categories"

    let listenedCategories: [ListenedCategory]

    init(listenedCategories: [ListenedCategory]) {
        self.listenedCategories = listenedCategories
    }

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    let mostListenedCategory = listenedCategories.first?.categoryTitle.localized ?? ""
                    let listenedTime = listenedCategories.first?.totalPlayedTime.storyTimeDescription ?? ""
                    let listenedEpisodes = "\(listenedCategories.first?.numberOfEpisodes ?? 0)"
                    StoryLabel(L10n.eoyStoryTopCategoriesTitle(mostListenedCategory), for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyStoryTopCategoriesSubtitle(listenedEpisodes, listenedTime), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                let headerSpacing = geometry.size.height * 0.054

                VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                    ForEach(0...min(listenedCategories.count, 3), id: \.self) { index in
                        category(row: index, geometry: geometry)
                    }
                }
                .padding([.leading, .trailing], 35)
                .padding(.top, headerSpacing)
            }
            .background(
                ZStack(alignment: .top) {
                    Color.black

                    StoryGradient()
                    .offset(x: -geometry.size.width * 0.4, y: -geometry.size.height * 0.22)
                    .clipped()
                }
                .ignoresSafeArea()
            )
        }
    }

    func category(row index: Int, geometry: GeometryProxy) -> some View {
        HStack(spacing: 24) {
            Text("\(index + 1)")
                .font(.custom("DM Sans", size: geometry.size.height * 0.025))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "8F97A4"))
                .offset(y: -5)
                .frame(width: geometry.size.width * 0.03)

            VStack(alignment: .leading) {
                Text("\(listenedCategories[safe: index]?.categoryTitle.localized ?? "")")
                    .font(.custom("DM Sans", size: geometry.size.height * 0.06))
                    .fontWeight(.medium)
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .if(index == 0) { view in
                        view
                            .modifier(CategoryStoryTextGradient())
                    }
                    .if(index != 0) { view in
                        view
                            .foregroundColor(Color(hex: "686C74"))
                    }


                Text("\(listenedCategories[safe: index]?.totalPlayedTime.storyTimeDescription ?? "")")
                    .font(.custom("DM Sans", size: geometry.size.height * 0.018))
                    .fontWeight(.medium)
                    .foregroundColor(index == 0 ? Color(hex: "FBFBFC") : Color(hex: "686C74"))
            }

            Spacer()
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

struct CategoryStoryTextGradient: ViewModifier {
    public func body(content: Content) -> some View {
        content
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
