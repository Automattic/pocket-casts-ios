import SwiftUI

struct MediaTrimBar: View {
    @ObservedObject var clipTime: ClipTime

    private enum Colors {
        static var trimBorderColor = Color(hex: "6B6B6B")
    }

    var body: some View {
        HStack(spacing: 0) {
            PlayButton(isPlaying: false)
                .frame(width: 70)
                .background(Colors.trimBorderColor.opacity(0.28))
                .modify { view in
                    if #available(iOS 16, *) {
                        view.clipShape(.rect(topLeadingRadius: 12,
                                             bottomLeadingRadius: 12,
                                             bottomTrailingRadius: 0,
                                             topTrailingRadius: 0))
                    } else {
                        view.clipShape(PCUnevenRoundedRectangle(topLeadingRadius: 12,
                                                                bottomLeadingRadius: 12,
                                                                bottomTrailingRadius: 0,
                                                                topTrailingRadius: 0))
                    }
                }
            MediaTrimView(duration: PlaybackManager.shared.duration(), startTime: $clipTime.start, endTime: $clipTime.end, playTime: $clipTime.playback)
        }
    }
}
