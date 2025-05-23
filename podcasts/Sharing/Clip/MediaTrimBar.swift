import SwiftUI
import PocketCastsDataModel

struct MediaTrimBar: View {
    @ObservedObject var clipTime: ClipTime

    @State var isPlaying: Bool = false

    let episode: Episode
    let clipUUID: String
    let analyticsSource: AnalyticsSource
    private let playbackManager = ClipPlaybackManager.shared

    private enum Constants {
        static var trimBorderColor = Color(hex: "6B6B6B").opacity(0.28)
        static var borderRadius: CGFloat = 12
        static var height: CGFloat = 70
    }

    init(clipTime: ClipTime, episode: Episode, clipUUID: String, analyticsSource: AnalyticsSource) {
        self.clipTime = clipTime
        self.episode = episode
        self.clipUUID = clipUUID
        self.isPlaying = false
        self.analyticsSource = analyticsSource
    }

    var body: some View {
        HStack(spacing: 0) {
            TrimPlayButton(isPlaying: $isPlaying)
                .frame(width: Constants.height)
                .background(Constants.trimBorderColor)
                .modify { view in
                    if #available(iOS 16, *) {
                        view.clipShape(.rect(topLeadingRadius: Constants.borderRadius,
                                             bottomLeadingRadius: Constants.borderRadius,
                                             bottomTrailingRadius: 0,
                                             topTrailingRadius: 0))
                    } else {
                        view.clipShape(PCUnevenRoundedRectangle(topLeadingRadius: Constants.borderRadius,
                                                                bottomLeadingRadius: Constants.borderRadius,
                                                                bottomTrailingRadius: 0,
                                                                topTrailingRadius: 0))
                    }
                }
                .onChange(of: isPlaying) { isPlaying in
                    if isPlaying {
                        playbackManager.play(episode: episode, clipTime: _clipTime)
                    } else {
                        playbackManager.stop()
                    }
                    let event: AnalyticsEvent = isPlaying ? .shareScreenPlayTapped : .shareScreenPauseTapped
                    Analytics.track(event, source: analyticsSource, properties: ["podcast_uuid": episode.parentIdentifier(), "episode_uuid": episode.uuid, "clip_uuid": clipUUID])
                }
                .onDisappear {
                    playbackManager.stop()
                }
            MediaTrimView(duration: episode.duration, startTime: $clipTime.start, endTime: $clipTime.end, playTime: $clipTime.playback)
                .onChange(of: clipTime.playback) { newValue in
                    if let currentTime = playbackManager.currentTime, abs(currentTime - newValue) > 0.1 {
                        playbackManager.seek(to: CMTime(seconds: newValue, preferredTimescale: 600))
                    }
                    playbackManager.currentTime = newValue
                }
        }
    }
}
