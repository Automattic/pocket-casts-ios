import SwiftUI

struct IntroStory2024: StoryView {
    let identifier: String = "intro"

    let backgroundColor = Color(hex: "EE661C")
    let backgroundTextColor = Color(hex: "EEB1F4")

    enum Constants {
        static let newStickerSize = CGSize(width: 172, height: 163)
        static let sticker2024Size = CGSize(width: 249, height: 188)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image("playback-sticker-new")
                        .resizable()
                        .frame(width: Constants.newStickerSize.width, height: Constants.newStickerSize.height)
                        .position(x: 26, y: 54, for: Constants.newStickerSize, in: geometry.frame(in: .local), corner: .topLeading)
                    Image("playback-sticker-2024")
                        .resizable()
                        .frame(width: Constants.sticker2024Size.width, height: Constants.sticker2024Size.height)
                        .position(x: -23, y: -50, for: Constants.sticker2024Size, in: geometry.frame(in: .local), corner: .bottomTrailing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        InfiniteScrollView()
                            .foregroundStyle(backgroundTextColor)

                    }
                    .ignoresSafeArea()
                )

            }
        }
        .background(backgroundColor)
        .enableProportionalValueScaling()
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }
}

private struct TwentyThreeParallaxModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var manager: MotionManager = .init(relativeToWhenStarting: true)
    var rollMultiplier: Double = 4
    var pitchMultiplier: Double = 40

    private let rollAndPitchBoundary = -1.4..<1.5

    func body(content: Content) -> some View {
        let roll = manager.roll.betweenOrClamped(to: rollAndPitchBoundary) * 7
        let pitch = manager.pitch.betweenOrClamped(to: rollAndPitchBoundary)
        return content
            .offset(x: roll * rollMultiplier, y: pitch * pitchMultiplier)
            .onAppear() {
                if !reduceMotion {
                    manager.start()
                }
            }
            .onDisappear() {
                if !reduceMotion {
                    manager.stop()
                }
            }
    }
}

struct IntroStory2024_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory2024()
    }
}

struct InfiniteScrollView: View {
    @State private var offset = CGFloat.zero

    @State private var contentHeight: CGFloat = 0

    let labels = [
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
        "Playback",
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: -16) {
                    // Duplicate the labels to facilitate infinite scrolling
                    ForEach(labels, id: \.self) { label in
                        Text(label.uppercased())
                            .font(.custom("Humane-Medium", fixedSize: 227))
                            .frame(width: geometry.size.width)
                            .multilineTextAlignment(.center)
                    }
                }
                .offset(y: offset)
                .onAppear {
                    contentHeight = geometry.size.height
                    startScrolling()
                }
            }
            .frame(height: contentHeight)  // Delegate height to scroll view
        }
    }

    private func startScrolling() {
        let totalHeight = CGFloat(labels.count) * 60
        let speed: CGFloat = 0.2

        Timer.scheduledTimer(withTimeInterval: 0.002, repeats: true) { _ in
            if offset <= -totalHeight {
                offset = contentHeight  // Reset offset back to height of scroll view
            }
            offset -= speed // Scroll down at constant speed
        }
    }
}
