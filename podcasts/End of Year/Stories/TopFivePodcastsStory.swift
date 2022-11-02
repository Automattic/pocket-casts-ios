import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopFivePodcastsStory: StoryView {
    let podcasts: [Podcast]

    let duration: TimeInterval = 5.seconds

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: podcasts[0])

                VStack {
                    Spacer()
                    Text(L10n.eoyStoryTopPodcasts)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * 0.07)
                        .minimumScaleFactor(0.01)
                        .opacity(0.8)
                        .padding(.bottom)
                        .padding(.top, geometry.size.height * 0.05)
                    VStack() {
                        ForEach(0...4, id: \.self) {
                            topPodcastRow($0)
                        }
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 40)

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
    func topPodcastRow(_ index: Int) -> some View {
        HStack(spacing: 16) {
            Text("\(index + 1).")
                .frame(width: 30)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

                if let podcast = podcasts[safe: index] {
                    ImageView(ServerHelper.imageUrl(podcastUuid: podcast.uuid, size: 280))
                        .frame(width: 65, height: 65)
                        .modifier(PodcastCover())
                } else {
                    Rectangle()
                        .frame(width: 65, height: 65)
                }

            VStack(alignment: .leading) {
                Text(podcasts[safe: index]?.title ?? "")
                    .lineLimit(2)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.01)
                Text(podcasts[safe: index]?.author ?? "").font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
            Spacer()
        }
        .opacity(podcasts[safe: index] != nil ? 1 : 0)
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: .topFivePodcasts)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: .topFivePodcasts)
    }

    func sharingAssets() -> [Any] {
            [
                StoryShareableProvider.new(AnyView(self)),
                StoryShareableText(L10n.eoyStoryTopPodcastsShareText)
            ]
    }
}

struct DummyStory_Previews: PreviewProvider {
    static var previews: some View {
        TopFivePodcastsStory(podcasts: [Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast()])
    }
}
