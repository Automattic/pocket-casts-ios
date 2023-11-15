import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct LongestEpisodeStory: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    let duration: TimeInterval = 5.seconds

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: 0.8, animation: Animation.spring(_:))

    var identifier: String = "longest_episode"

    let episode: Episode

    let podcast: Podcast

    @State var firstCover: Double = 0.4
    @State var secondCover: Double = 0.32
    @State var thirdCover: Double = 0.24
    @State var fourthCover: Double = 0.16
    @State var fifthCover: Double = 0.08
    @State var sixthCover: Double = 0

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
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                        .offset(x: -geometry.size.width * firstCover, y: geometry.size.width * firstCover)
                        .modifier(animationViewModel.animate($firstCover, to: 0.4))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.55, height: geometry.size.width * 0.55)
                        .offset(x: -geometry.size.width * secondCover, y: geometry.size.width * secondCover)
                        .modifier(animationViewModel.animate($secondCover, to: 0.32))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(x: -geometry.size.width * thirdCover, y: geometry.size.width * thirdCover)
                        .modifier(animationViewModel.animate($thirdCover, to: 0.24))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.65, height: geometry.size.width * 0.65)
                        .offset(x: -geometry.size.width * fourthCover, y: geometry.size.width * fourthCover)
                        .modifier(animationViewModel.animate($fourthCover, to: 0.16))

                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                        .offset(x: -geometry.size.width * fifthCover, y: geometry.size.width * fifthCover)
                        .modifier(animationViewModel.animate($fifthCover, to: 0.08))

                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                        .offset(x: -geometry.size.width * sixthCover, y: geometry.size.width * sixthCover)
                        .modifier(animationViewModel.animate($sixthCover, to: 0))
                }
                .offset(x: geometry.size.width * 0.04, y: geometry.size.height * 0.04)
            }
        }.background(.black)
        .onAppear {
            if animated {
                setInitialCoverOffsetForAnimation()
                animationViewModel.play()
            }
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func onPause() {
        animationViewModel.pause()
    }

    func onResume() {
        animationViewModel.play()
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

    private func setInitialCoverOffsetForAnimation() {
        firstCover = 0.8
        secondCover = 0.8
        thirdCover = 0.8
        fourthCover = 0.8
        fifthCover = 0.8
        sixthCover = 0.8
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
