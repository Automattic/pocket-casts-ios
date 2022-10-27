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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: listenedCategories[0].mostListenedPodcast)

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

                    HStack {
                        CategoryPillar(color: tintColor, textColor: darkTintColor, text: "1", title: "Title", subtitle: "Subtitle")
                        CategoryPillar(color: tintColor, textColor: darkTintColor, text: "1", title: "Title", subtitle: "Subtitle")
                        CategoryPillar(color: tintColor, textColor: darkTintColor, text: "1", title: "Title", subtitle: "Subtitle")
                    }

                    VStack {
                        ForEach(0 ..< min(listenedCategories.count, 5), id: \.self) { x in
                            HStack(spacing: 16) {
                                Text("\(x + 1).")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                Image("discover_cat_1")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                                Text(listenedCategories[x].categoryTitle.localized)
                                    .lineLimit(2)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                VStack(alignment: .trailing) {
                                    Text("\(listenedCategories[x].numberOfPodcasts)").font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Podcasts")
                                        .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 40)
                }
            }
        }
    }
}

struct CategoryPillar: View {
    let color: Color

    let textColor: Color

    let text: String

    let title: String

    let subtitle: String

    var body: some View {
        VStack {
            VStack {
                Text(title)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                Text(subtitle)
                    .lineLimit(1)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(0.8)
                ZStack {
                    VStack {
                        Image("square_perspective")
                            .renderingMode(.template)
                            .foregroundColor(color)
                    }

                    let values: [CGFloat] = [1, 0, 0.50, 1, 0, 0]
                    VStack {
                        Text(text)
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
            }
            .zIndex(1)

            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [color, .black.opacity(0)]), startPoint: .top, endPoint: .bottom))
                .padding(.top, -39)
                .frame(height: 200)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

#if DEBUG
struct TopListenedCategories_Previews: PreviewProvider {
    static var previews: some View {
        TopListenedCategories(listenedCategories: [ListenedCategory(numberOfPodcasts: 5, categoryTitle: "Test", mostListenedPodcast: Podcast.previewPodcast(), totalPlayedTime: 300)])
    }
}
#endif
