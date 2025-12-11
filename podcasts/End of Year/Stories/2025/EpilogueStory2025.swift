import SwiftUI

struct EpilogueStory2025: StoryView {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    var identifier: String = "ending"

    private var startDelay = 0.25
    private var assetDelay = 0.07
    private var opacityAnimation: Animation = .linear(duration: 0.34)
    private var moveAnimation: Animation = .timingCurve(0.40, 0.00, 0.00, 1.00, duration: 1.2)

    @State private var offset: CGFloat = 30
    @State private var opacity: CGFloat = 0.0
    @State private var isAnimating: Bool = true

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Image("eoy25_pc_logo")
                    .padding(.bottom, 24)
                    .opacity(opacity)
                    .offset(y: offset)
                    .if(isAnimating) {
                        $0.animation(moveAnimation, value: offset)
                            .animation(opacityAnimation.delay(startDelay), value: opacity)
                    }

                Text(L10n.playback2025EndStoryTitle)
                    .font(.system(size: 25, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                    .opacity(opacity)
                    .offset(y: offset)
                    .if(isAnimating) {
                        $0.animation(moveAnimation.delay(assetDelay), value: offset)
                            .animation(opacityAnimation.delay(startDelay + assetDelay), value: opacity)
                    }

                Text(L10n.playback2025EndStoryDescription)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .offset(y: offset)
                    .if(isAnimating) {
                        $0.animation(moveAnimation.delay(assetDelay + assetDelay), value: offset)
                        .animation(opacityAnimation.delay(startDelay + assetDelay + assetDelay), value: opacity)
                    }
            }
            .padding(.horizontal, 24)
            Spacer()
            Button(L10n.eoyStoryReplay) {
                StoriesController.shared.replay()
                Analytics.track(.endOfYearStoryReplayButtonTapped, properties: ["current_year": "2025"])
            }
            .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: foregroundColor))
            .allowsHitTesting(true)
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
            .minimumScaleFactor(0.8)
        }
        .foregroundStyle(foregroundColor)
        .background {
            backgroundColor
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .enableProportionalValueScaling()
        .onAppear {
            self.isAnimating = true
            self.offset = 0
            self.opacity = 1
        }
        .onDisappear {
            self.isAnimating = false
            self.offset = 30
            self.opacity = 0
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }
}

#Preview {
    EpilogueStory2025()
}
