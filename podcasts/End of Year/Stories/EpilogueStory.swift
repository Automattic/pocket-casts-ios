import SwiftUI
import PocketCastsServer
import CoreHaptics

struct EpilogueStory: StoryView {
    @Environment(\.renderForSharing) var renderForSharing: Bool
    @ObservedObject private var visibility = Visiblity()
    @State private var engine: CHHapticEngine?

    var duration: TimeInterval = 5.seconds

    var identifier: String = "epilogue"

    var isPlus: Bool {
        SubscriptionHelper.hasActiveSubscription()
    }

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
                        GradientHolographicEffect(parentSize: geometry.size) {
                            Image("heart")
                                .renderingMode(.template)
                        }
                    } else {
                        Image("heart")
                    }

                    StoryLabel(L10n.eoyStoryEpilogueTitle, for: .title, geometry: geometry)
                    StoryLabel(L10n.eoyStoryEpilogueSubtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }.allowsHitTesting(false)

                Button(L10n.eoyStoryReplay) {
                    StoriesController.shared.replay()
                    Analytics.track(.endOfYearStoryReplayButtonTapped)
                }
                .buttonStyle(StoriesButtonStyle(color: Constants.backgroundColor, icon: Image("eoy-replay-icon")))
                .opacity(renderForSharing ? 0 : 1)
                .padding(.top, 36)

                Spacer()
            }
            .background(
                ZStack(alignment: .top) {
                    Color.black

                    background
                    .offset(x: -geometry.size.width * 0.4, y: -geometry.size.height * 0.22)
                    .clipped()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .onAppear(perform: prepareHaptics)
            )
        }
    }

    @ViewBuilder
    var background: some View {
        if isPlus {
            PlusStoryGradient()
        } else {
            StoryGradient()
        }
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

private struct GradientHolographicEffect<Content>: View where Content: View {
    @StateObject var motion = MotionManager(options: .attitude)

    var parentSize: CGSize = UIScreen.main.bounds.size
    var mode: Mode = .background
    let content: () -> Content

    private let multiplier = 0.1

    var body: some View {
        content()
            .foregroundColor(mode == .background ? .clear : nil)
            .overlay(mode == .overlay ? gradientView.blendMode(.overlay) : nil)
            .background(mode == .background ? gradientView : nil)
            .onAppear() {
                motion.start()
            }.onDisappear() {
                motion.stop()
            }
    }

    @ViewBuilder
    private var gradientView: some View {
        GeometryReader { proxy in
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
                    Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
                    Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.74),
                    Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0, y: -0.12),
                endPoint: UnitPoint(x: 1, y: 1.39)
            )
            .scaleEffect(.init(width: 1.1, height: 1.1))
            .rotationEffect(Angle(degrees: (motion.roll / .pi) * 360))
            .mask(content())
        }.allowsHitTesting(false)
    }

    enum Mode {
        case overlay, background
    }
}

struct StoriesButtonStyle: ButtonStyle {
    let color: Color
    let icon: Image?

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack() {
            icon?
                .resizable()
                .frame(width: 24, height: 24)
            configuration.label
        }
        .font(.custom("DM Sans", size: 14).weight(.semibold))
        .foregroundColor(color)
        .padding(EdgeInsets(top: 16, leading: 78, bottom: 16, trailing: 78))
        .background(
            RoundedRectangle(cornerRadius: 4 ).fill(.white)
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
