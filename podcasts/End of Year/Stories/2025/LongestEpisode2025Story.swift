import SwiftUI
import PocketCastsDataModel

struct LongestEpisode2025Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @Environment(\.animated) var animated: Bool

    var identifier: String = "longest_episode"

    let episode: Episode

    let podcast: Podcast

    private let backgroundColor = Color(hex: "#17423B")
    private let foregroundColor = Color.black

    var body: some View {
        VStack(alignment: .center) {
            headerView
            Spacer()
            PodcastCover(podcastUuid: podcast.uuid)
                .frame(width: 196, height: 196)
            Spacer()
            StoryFooter2024(title: "",
                            description: L10n.playback2024LongestEpisodeDescription(episode.title ?? "unknown", podcast.title ?? "unknown"))
        }
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
    }

    @ViewBuilder var headerView: some View {
        let timeString = episode.playedUpTo.storyTimeDescriptionForSharing
        StoryHeader2025(title: L10n.playback2024LongestEpisodeTitle(timeString), description: "Hope you stretched first!")
    }

//    @ViewBuilder func covers() -> some View {
//        GeometryReader { geometry in
//            PodcastCoverContainer(geometry: geometry) {
//                ZStack {
//                    PodcastCover(podcastUuid: podcast.uuid)
//                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
//                        .offset(x: -geometry.size.width * firstCover, y: geometry.size.width * firstCover)
//                        .modifier(animationViewModel.animate($firstCover, to: 0.4))
//
//                    PodcastCover(podcastUuid: podcast.uuid)
//                        .frame(width: geometry.size.width * 0.55, height: geometry.size.width * 0.55)
//                        .offset(x: -geometry.size.width * secondCover, y: geometry.size.width * secondCover)
//                        .modifier(animationViewModel.animate($secondCover, to: 0.32))
//
//                    PodcastCover(podcastUuid: podcast.uuid)
//                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
//                        .offset(x: -geometry.size.width * thirdCover, y: geometry.size.width * thirdCover)
//                        .modifier(animationViewModel.animate($thirdCover, to: 0.24))
//
//                    PodcastCover(podcastUuid: podcast.uuid)
//                        .frame(width: geometry.size.width * 0.65, height: geometry.size.width * 0.65)
//                        .offset(x: -geometry.size.width * fourthCover, y: geometry.size.width * fourthCover)
//                        .modifier(animationViewModel.animate($fourthCover, to: 0.16))
//
//                    PodcastCover(podcastUuid: podcast.uuid)
//                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
//                        .offset(x: -geometry.size.width * fifthCover, y: geometry.size.width * fifthCover)
//                        .modifier(animationViewModel.animate($fifthCover, to: 0.08))
//
//                    PodcastCover(podcastUuid: podcast.uuid, higherQuality: true)
//                        .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
//                        .offset(x: -geometry.size.width * sixthCover, y: geometry.size.width * sixthCover)
//                        .modifier(animationViewModel.animate($sixthCover, to: 0))
//                }
//                .offset(x: geometry.size.width * 0.04, y: geometry.size.height * 0.09)
//            }
//        }
//    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryLongestEpisodeShareText("%1$@"), episode: episode, year: .y2025)
        ]
    }
}
