import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct LongestEpisodeStory: StoryView {
    let duration: TimeInterval = 5.seconds

    let episode: Episode

    let podcast: Podcast

    var backgroundColor: Color {
        Color(podcast.bgColor())
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack {
                VStack {
                    ImageView(ServerHelper.imageUrl(podcastUuid: podcast.uuid, size: 280))
                        .frame(width: 230, height: 230)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(4)
                        .shadow(radius: 2, x: 0, y: 1)
                        .accessibilityHidden(true)
                    Text("The longest episode you listened to was \(episode.title ?? "") from the podcast \(podcast.title ?? "")")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(tintColor)
                        .padding(.top)
                    Text("This episode was \(episode.duration.localizedTimeDescription ?? "")")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tintColor)
                        .padding(.top)
                }
                .padding(.leading, 40)
                .padding(.trailing, 40)
            }
        }
    }
}

struct LongestEpisodeStory_Previews: PreviewProvider {
    static var previews: some View {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        return LongestEpisodeStory(episode: episode, podcast: Podcast.previewPodcast())
    }
}
