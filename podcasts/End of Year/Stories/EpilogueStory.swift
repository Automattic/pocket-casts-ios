import SwiftUI
import CoreHaptics

struct EpilogueStory: StoryView {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @ObservedObject private var visibility = Visiblity()
    @State private var engine: CHHapticEngine?

    var duration: TimeInterval = 5.seconds

    var identifier: String = "epilogue"

    var body: some View {
        GeometryReader { geometry in
            if visibility.isVisible {
                WelcomeConfetti(type: .normal)
                    .onAppear(perform: playHaptics)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            PodcastCoverContainer(geometry: geometry) {
                Spacer()

                StoryLabelContainer(topPadding: 0, geometry: geometry) {
                    if visibility.isVisible {
                        HolographicEffect(parentSize: geometry.size) {
                            Image("heart")
                                .renderingMode(.template)
                        }
                    } else {
                        Image("heart")
                    }

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
        }.background(Constants.backgroundColor.allowsHitTesting(false).onAppear(perform: prepareHaptics))
    }

    func onAppear() {
        self.visibility.isVisible = true
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    private enum Constants {
        static let backgroundColor = Color.black
    }

    private class Visiblity: ObservableObject {
        @Published var isVisible = false
    }

    // MARK: - Haptics
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    private func playHaptics() {
        guard let engine else { return }
        var events = [CHHapticEvent]()

        for i in stride(from: 0, to: 1, by: 0.1) {
            let value = Float(i)

            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: value)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: value)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }

        for i in stride(from: 0, to: 1, by: 0.1) {
            let value = Float(1 - i)

            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: value)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: value)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 1 + i)
            events.append(event)
        }

        guard let pattern = try? CHHapticPattern(events: events, parameters: []), let player = try? engine.makePlayer(with: pattern) else {
            return
        }

        // Make the haptics a little more in sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            try? player.start(atTime: 0)
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
