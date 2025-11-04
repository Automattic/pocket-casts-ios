import SwiftUI

struct EpilogueStory2025: StoryView {
    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    var identifier: String = "ending"

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Image("eoy25_pc_logo")
                    .padding(.bottom, 24)
                Text(L10n.playback2025EndStoryTitle)
                    .font(.system(size: 25, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                Text(L10n.playback2025EndStoryDescription)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            Spacer()
            Button(L10n.eoyStoryReplay) {
                StoriesController.shared.replay()
                Analytics.track(.endOfYearStoryReplayButtonTapped, properties: ["year": "2025"])
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
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }
}
