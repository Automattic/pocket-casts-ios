import SwiftUI
import PocketCastsDataModel

struct TopListenedCategoriesStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    let contrastColor: CategoriesContrastingColors

    init(listenedCategories: [ListenedCategory]) {
        self.listenedCategories = listenedCategories
        self.contrastColor = CategoriesContrastingColors(podcast: listenedCategories.reversed()[0].mostListenedPodcast)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(backgroundColor: contrastColor.backgroundColor, foregroundColor: contrastColor.foregroundColor)

                VStack {
                    Text(L10n.eoyStoryTopCategories)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                        .padding(.bottom)
                        .padding(.top, geometry.size.height * 0.05)

                    HStack(alignment: .bottom, spacing: 25) {
                        ForEach([1, 0, 2], id: \.self) {
                            pillar($0)
                        }
                    }
                }
                .padding(.bottom, 100)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("logo_white")
                            .padding(.bottom, 40)
                        Spacer()
                    }
                }
            }
        }
    }

    @ViewBuilder
    func pillar(_ index: Int) -> some View {
        if let listenedCategory = listenedCategories[safe: index] {
            CategoryPillar(color: contrastColor.tintColor, text: "\(index + 1)", title: listenedCategory.categoryTitle.localized, subtitle: listenedCategory.totalPlayedTime.localizedTimeDescription ?? "", height: CGFloat(200 - (index * 55)))
                .padding(.bottom, index == 0 ? 70 : 0)
        } else {
            CategoryPillar(color: contrastColor.tintColor, text: "", title: "", subtitle: "", height: 200)
                .opacity(0)
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: .topCategories)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: .topCategories)
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
