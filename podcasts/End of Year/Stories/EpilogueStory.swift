import SwiftUI

struct EpilogueStory: StoryView {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @ObservedObject private var visibility = Visiblity()
    var duration: TimeInterval = 5.seconds

    var identifier: String = "epilogue"

    var body: some View {
        GeometryReader { geometry in
            if visibility.isVisible {
                WelcomeConfetti(type: .normal)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            PodcastCoverContainer(geometry: geometry) {
                Spacer()

                StoryLabelContainer(topPadding: 0, geometry: geometry) {
                    Image("heart")

                    let pocketCasts = "Pocket Casts".nonBreakingSpaces()

                    StoryLabel(L10n.eoyStoryEpilogueTitle, highlighting: [pocketCasts], for: .title)
                    StoryLabel(L10n.eoyStoryEpilogueSubtitle, for: .subtitle)
                        .opacity(0.8)
                }.allowsHitTesting(false)

                Button(L10n.eoyStoryReplay) {
                    StoriesController.shared.replay()
                    Analytics.track(.endOfYearStoryReplayButtonTapped)
                }
                .buttonStyle(ReplayButtonStyle(color: Constants.backgroundColor))
                .opacity(renderForSharing ? 0 : 1)
                .padding(.top, 36)

                Spacer()
            }
        }.background(Constants.backgroundColor)
    }

    func onAppear() {
        self.visibility.isVisible = true
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    private enum Constants {
        static let backgroundColor = Color(hex: "#1A1A1A")

    private class Visiblity: ObservableObject {
        @Published var isVisible = false
    }
    }
}

struct ReplayButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Image("eoy-replay-icon")
            configuration.label
        }
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(color)
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 15))
        .background(
            Capsule().fill(.white)
        )
        .contentShape(Rectangle())
        .applyButtonEffect(isPressed: configuration.isPressed)
    }
}

struct EpilogueStory_Previews: PreviewProvider {
    static var previews: some View {
        EpilogueStory()
    }
}
