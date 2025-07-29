import Lottie
import SwiftUI

/// A button style for a Lottie animations which scales and, optionally, replays the animation on press.
/// Haptic feedback can also be provided for when the button is pressed
struct PressableLottieButtonStyle: ButtonStyle {
    let animation: LottieAnimation?
    let haptic: () -> Void
    let replayOnPress: Bool

    func makeBody(configuration: Configuration) -> some View {
        PressableLottieButtonBody(
            configuration: configuration,
            haptic: haptic,
            animation: animation,
            replayOnPress: replayOnPress
        )
    }

    struct PressableLottieButtonBody: View {
        let configuration: Configuration
        let haptic: () -> Void
        let animation: LottieAnimation?
        let replayOnPress: Bool

        @State private var reloadTrigger = UUID()
        @State private var lastPressed = false

        var body: some View {
            VStack(spacing: 8) {
                LottieWrapperView(animation: animation, trigger: reloadTrigger)
                    .scaleEffect(configuration.isPressed ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)

                configuration.label
            }
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && !lastPressed {
                    haptic()
                    if replayOnPress {
                        reloadTrigger = UUID()
                    }
                }
                lastPressed = isPressed
            }
        }
    }

    struct LottieWrapperView: View {
        let animation: LottieAnimation?
        let trigger: UUID

        var body: some View {
            LottieView(animation: animation)
                .playbackMode(.playing(.toProgress(0.99, loopMode: .playOnce)))
                .id(trigger)
                .frame(height: 72)
        }
    }
}
