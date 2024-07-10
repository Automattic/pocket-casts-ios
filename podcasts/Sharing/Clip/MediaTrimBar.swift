import SwiftUI

struct MediaTrimBar: View {
    @ObservedObject var clipTime: ClipTime

    private enum Constants {
        static var trimBorderColor = Color(hex: "6B6B6B").opacity(0.28)
        static var borderRadius: CGFloat = 12
        static var height: CGFloat = 70
    }

    var body: some View {
        HStack(spacing: 0) {
            PlayButton(isPlaying: false)
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
            MediaTrimView(duration: PlaybackManager.shared.duration(), startTime: $clipTime.start, endTime: $clipTime.end, playTime: $clipTime.playback)
        }
    }
}
