import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct TopOnePodcastStory: StoryView {
    var duration: TimeInterval = 5.seconds

    let topPodcast: TopPodcast

    var backgroundColor: Color {
        Color(topPodcast.podcast.bgColor())
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DynamicBackgroundView(podcast: topPodcast.podcast)

                VStack {
                    VStack {
                        ImageView(ServerHelper.imageUrl(podcastUuid: topPodcast.podcast.uuid, size: 280))
                            .frame(width: 230, height: 230)
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(4)
                            .shadow(radius: 2, x: 0, y: 1)
                            .accessibilityHidden(true)

                        Text(L10n.eoyStoryTopPodcast(topPodcast.podcast.title ?? "", topPodcast.podcast.author ?? ""))
                            .foregroundColor(.white)
                            .font(.system(size: 25, weight: .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.12)
                            .minimumScaleFactor(0.01)
                        Text(L10n.eoyStoryTopPodcastSubtitle(topPodcast.numberOfPlayedEpisodes, topPodcast.totalPlayedTime.localizedTimeDescription ?? ""))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxHeight: geometry.size.height * 0.07)
                            .minimumScaleFactor(0.01)
                            .opacity(0.8)
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 40)
                }
            }
        }
    }
}

struct TopOnePodcastStory_Previews: PreviewProvider {
    static var previews: some View {
        TopOnePodcastStory(topPodcast: TopPodcast(podcast: Podcast.previewPodcast(), numberOfPlayedEpisodes: 10, totalPlayedTime: 3600))
    }
}
