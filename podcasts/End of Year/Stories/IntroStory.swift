import SwiftUI

struct IntroStory: StoryView {
    var duration: TimeInterval = 5.seconds
    let identifier: String = "intro"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    TwentyThree()

                    Image("2023-title")

                    Twenty()
                }
                .background(.black)
            }
            .enableProportionalValueScaling()
        }
    }

    private struct TwentyThree: View {
        @ProportionalValue(with: .width) var xPosition = 0.5
        @ProportionalValue(with: .height) var yPosition = 0.5

        var body: some View {
            Image("23")
                .position(x: xPosition, y: yPosition)
                .modifier(TwentyThreeParallaxModifier())
        }
    }

    private struct Twenty: View {
        @ProportionalValue(with: .width) var xPosition = 0.5
        @ProportionalValue(with: .height) var yPosition = 0.48

        var body: some View {
            Image("20")
                .position(x: xPosition, y: yPosition)
                .modifier(TwentyThreeParallaxModifier())
        }
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

/// Adds a not so subtle parallax effect to the app icon as the user tilts their device
private struct TwentyThreeParallaxModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var manager: MotionManager = .init()

    func body(content: Content) -> some View {
        let roll = manager.roll * 10
        let pitch = manager.pitch
        content
            .offset(x: roll * 4, y: pitch * 40)
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

struct IntroStory_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory()
    }
}
