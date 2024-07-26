import SwiftUI
import PocketCastsDataModel

struct MediaTrimBar: View {
    @ObservedObject var clipTime: ClipTime

    let episode: any BaseEpisode
    @State var isPlaying: Bool = false

    private let playbackManager = ClipPlaybackManager.shared

    private enum Constants {
        static var trimBorderColor = Color(hex: "6B6B6B").opacity(0.28)
        static var borderRadius: CGFloat = 12
        static var height: CGFloat = 70
    }

    init(clipTime: ClipTime, episode: any BaseEpisode) {
        self.clipTime = clipTime
        self.episode = episode
        self.isPlaying = false
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
