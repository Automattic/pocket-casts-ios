import SwiftUI

struct IntroStory: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool

    let identifier: String = "intro"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image("2023-title")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .modifier(IconParallaxModifier())

                    Image("22")
                        .resizable()
                        .scaledToFit()
                        .frame(height: geometry.size.height * 0.3)
                        .position(x: geometry.size.width * 0.13, y: geometry.size.height * 0.71)
                        .modifier(TwentyThreeParallaxModifier(rollMultiplier: 6, pitchMultiplier: 60))


                    Image("0")
                        .resizable()
                        .scaledToFit()
                        .frame(height: geometry.size.height * 0.3)
                        .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.29)
                        .modifier(TwentyThreeParallaxModifier(rollMultiplier: 6, pitchMultiplier: 60))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        ZStack {
                            Color.black

                            Image("2")
                                .resizable()
                                .scaledToFit()
                                .frame(height: geometry.size.height * 0.5)
                                .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.34)
                                .modifier(TwentyThreeParallaxModifier(rollMultiplier: 5, pitchMultiplier: 50))

                            Image("3")
                                .resizable()
                                .scaledToFit()
                                .frame(height: geometry.size.height * 0.5)
                                .position(x: geometry.size.width * 0.75, y: geometry.size.height * 0.84)
                                .modifier(TwentyThreeParallaxModifier())
                        }
                        .clipped()
                    }
                        .ignoresSafeArea()
                )

                if !renderForSharing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image("logo")
                                .padding(.bottom, geometry.size.height * 0.06)
                            Spacer()
                        }
                    }
                }
            }
        }
        .background(.black)
        .enableProportionalValueScaling()
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self))
        ]
    }

    func hideShareButton() -> Bool {
        true
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
        let roll = manager.roll.betweenOrClamped(to: rollAndPitchBoundary) * 10
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

extension EndOfYear {
    static var defaultDuration = 7.seconds
}

struct IntroStory_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory()
    }
}
