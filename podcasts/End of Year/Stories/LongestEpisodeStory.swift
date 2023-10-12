import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct LongestEpisodeStory: ShareableStory {
    let duration: TimeInterval = 5.seconds

    var identifier: String = "longest_episode"

    let episode: Episode

    let podcast: Podcast

    var backgroundColor: Color {
        Color(podcast.bgColor())
    }

    var tintColor: Color {
        .white
    }

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    let podcastTitle = podcast.title ?? ""
                    let episodeTitle = episode.title ?? ""
                    StoryLabel(L10n.eoyStoryLongestEpisode(episode.duration.localizedTimeDescription ?? ""), for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyStoryLongestEpisodeSubtitle(episodeTitle, podcastTitle), for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                ZStack {
                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                        .offset(x: -geometry.size.width * 0.4, y: geometry.size.width * 0.4)

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.55, height: geometry.size.width * 0.55)
                        .offset(x: -geometry.size.width * 0.32, y: geometry.size.width * 0.32)

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(x: -geometry.size.width * 0.24, y: geometry.size.width * 0.24)

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.65, height: geometry.size.width * 0.65)
                        .offset(x: -geometry.size.width * 0.16, y: geometry.size.width * 0.16)

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                        .offset(x: -geometry.size.width * 0.08, y: geometry.size.width * 0.08)

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                }
                .offset(x: geometry.size.width * 0.04, y: geometry.size.height * 0.05)
            }
        }.background(.black)
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
            StoryShareableText(L10n.eoyStoryLongestEpisodeShareText("%1$@"), episode: episode)
        ]
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
