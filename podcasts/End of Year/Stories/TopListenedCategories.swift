import SwiftUI
import PocketCastsDataModel

struct TopListenedCategories: StoryView {
    var duration: TimeInterval = 5.seconds

    let listenedCategories: [ListenedCategory]

    private var podcastForBackground: Podcast {
        listenedCategories.reversed()[0].mostListenedPodcast
    }

    var tintColor: Color {
        ColorManager.darkThemeTintForPodcast(podcastForBackground).color
    }

    var darkTintColor: Color {
        ColorManager.lightThemeTintForPodcast(podcastForBackground).color
    }

    enum StaticColor {
        static let background = UIColor(hex: "#744F9D").color
        static let blobColor = UIColor(hex: "#301E3E").color
        static let pillarColor = UIColor(hex: "#FE7E61").color
        static let textColor: Color = .white
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(backgroundColor: StaticColor.background, foregroundColor: StaticColor.blobColor)

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
            CategoryPillar(color: StaticColor.pillarColor, textColor: .white, text: "\(index + 1)", title: listenedCategory.categoryTitle.localized, subtitle: listenedCategory.totalPlayedTime.localizedTimeDescription ?? "", height: CGFloat(200 - (index * 55)))
                .padding(.bottom, index == 0 ? 70 : 0)
        } else {
            CategoryPillar(color: tintColor, textColor: darkTintColor, text: "", title: "", subtitle: "", height: 200)
                .opacity(0)
        }
    }
}

struct CategoryPillar: View {
    let color: Color
    let textColor: Color
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(width: 90)
                            .padding(.bottom)

                        ZStack(alignment: .top) {
                            ZStack {
                                Image("square_perspective")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 90, height: 52)
                                    .foregroundColor(color)

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
