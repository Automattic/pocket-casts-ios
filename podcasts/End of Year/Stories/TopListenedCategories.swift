import SwiftUI
import PocketCastsDataModel

struct TopListenedCategories: StoryView {
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
}

struct CategoryPillar: View {
    let color: Color
    let text: String
    let title: String
    let subtitle: String
    let height: CGFloat

    var body: some View {
        VStack {
            ZStack {
                ZStack {
                    VStack {
                        Text(title)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 90)
                            .fixedSize()
                        Text(subtitle)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(width: 90)
                            .padding(.bottom)
                            .fixedSize()

                        ZStack(alignment: .top) {
                            ZStack {
                                Image("square_perspective")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 90, height: 52)
                                    .foregroundColor(color)

                                let whiteContrast = color.contrast(with: .white)
                                let textColor = whiteContrast < 2 ? UIColor.black.color : UIColor.white.color

                                let values: [CGFloat] = [1, 0, 0.50, 1, 0, 0]
                                VStack {
                                    Text("\(text) ")
                                        .font(.system(size: 18, weight: .heavy))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(textColor)
                                        .padding(.leading, -8)
                                }
                                .transformEffect(CGAffineTransform(
                                    a: values[0], b: values[1],
                                    c: values[2], d: values[3],
                                    tx: 0, ty: 0
                                ))
                                .rotationEffect(.init(degrees: -30))
                            }
                            .zIndex(1)

                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [color, .black.opacity(0)]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 90, height: height)
                                .padding(.top, 26)


                        }
                    }

                    Spacer()
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Given a podcast, check if the colors contrast is good
/// If not, return default hardcoded colors.
struct CategoriesContrastingColors {
    let backgroundColor: Color
    let foregroundColor: Color
    let tintColor: Color

    init(podcast: Podcast) {
        let backgroundColorForPodcast = ColorManager.backgroundColorForPodcast(podcast).color
        let darkThemeTintForPodcast = ColorManager.darkThemeTintForPodcast(podcast).color
        let lightThemeTintForPodcast = ColorManager.lightThemeTintForPodcast(podcast).color

        if backgroundColorForPodcast.contrast(with: darkThemeTintForPodcast) > 2 {
            backgroundColor = backgroundColorForPodcast
            foregroundColor = lightThemeTintForPodcast
            tintColor = darkThemeTintForPodcast
        } else {
            backgroundColor = UIColor(hex: "#744F9D").color
            foregroundColor = UIColor(hex: "#301E3E").color
            tintColor = UIColor(hex: "#FE7E61").color
        }
    }
}

#if DEBUG
struct TopListenedCategories_Previews: PreviewProvider {
    static var previews: some View {
        TopListenedCategories(listenedCategories: [
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Test category big title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Small title", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300),
            ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Category", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300)
        ])
    }
}
#endif
