import SwiftUI

struct IntroStory2024: StoryView {
    let identifier: String = "intro"

    let backgroundColor = Color(hex: "EE661C")
    let backgroundTextColor = Color(hex: "EEB1F4")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image("playback-sticker-new")
                        .resizable()
                        .frame(width: 172, height: 163)
                        .position(x: (172/2) + 26, y: 54 + (163/2))
                    Image("playback-sticker-2024")
                        .resizable()
                        .frame(width: 249, height: 188)
                        .position(x: geometry.size.width - (23 + 249/2), y: geometry.size.height - (188/2) - 50)
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

    private struct Constants {
        // Percentage based on total view height
        static let imageVerticalPadding = 0.10

        static let spaceBetweenImageAndText = 24.0

        static let fontSize = 22.0
        static let textHorizontalPadding = 35.0
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
                // Use a VStack to hold the labels
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
