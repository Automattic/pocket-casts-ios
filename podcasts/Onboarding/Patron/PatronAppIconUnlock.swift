import SwiftUI
import PocketCastsServer
import CoreHaptics

struct PatronAppIconUnlock: View {
    let viewModel: PatronWelcomeViewModel

    @StateObject private var haptics = PatronIconHaptics()

    // Limit the width on larger devices
    @Environment(\.horizontalSizeClass) private var sizeClass

    // Disable all animations if the user has enabled the reduce motion setting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Used to fade the pinwheel background in during the unlock
    @State private var unlockProgress: Double = 0

    // Once unlocked, we'll start the icon animations
    @State private var isUnlocked = false

    // After the last icon is set this is set to prevent animating again
    @State private var animationsFinished = false

    // Selected icon support
    @Namespace var namespace
    @State private var selectedIconIndex: Int? = nil

    var isPlus: Bool {
        SubscriptionHelper.hasActiveSubscription()
    }

    private var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 667
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if !isUnlocked {
                    WelcomeConfetti(type: .normal)
                        .onAppear { haptics.confetti() }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                // Width limiting ZStack for larger devices to allow the content to stay centered
                ZStack {
                    thankYouView

                    VStack {
                        if selectedIconIndex != nil {
                            Spacer()
                            selectedIconView
                            Spacer()
                        } else {
                            if isSmallScreen {
                                iconsView
                                    .scaleEffect(0.8)
                                    .padding(.bottom, -30)
                            } else {
                                iconsView
                            }
                        }
                        continueButton
                    }
                }
                .frame(maxWidth: sizeClass == .regular ? proxy.size.width * 0.5 : nil)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(pinWheelBackground)
        .background(Color(hex: "F3F0FE"))
        .onChange(of: isUnlocked) { newValue in
            guard newValue, !reduceMotion else { return }

            haptics.spring()
        }
    }

    /// An image of sunrays that expands the full size of the screen and rotates when unlocked
    private var pinWheelBackground: some View {
        Image("patron-sun-rays")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: .infinity)
            .foregroundColor(Color.white)
            .background(Color(hex: "9583F8"))
            .scaleEffect(5)

            // Rotate the image indefinitely once we've unlocked
            .rotationEffect(.degrees(isUnlocked ? 0 : 360))
            .accessibilityAnimation(.linear.speed(isUnlocked ? 0.03 : 5).repeatForever(autoreverses: false), value: isUnlocked)

            // Fade the rays in during the unlock process
            .opacity(0.2 * (isUnlocked ? 1.0 : unlockProgress))
            .accessibilityAnimation(.linear, value: unlockProgress)
    }

    /// The next/continue button that fades in after the animations finish, and hides if we've selected an icon
    @ViewBuilder private var continueButton: some View {
        if selectedIconIndex == nil {
            Spacer()

            Button(L10n.continue) {
                viewModel.continueTapped()
            }
            .buttonStyle(PlusGradientFilledButtonStyle(plan: .patron))
            .disabled(animationsFinished == false)
            .opacity(animationsFinished ? 1 : 0)
            .accessibilityAnimation(.linear(duration: PatronConstants.delay).delay(PatronConstants.appearDelay)
                                    , value: animationsFinished)
            .opacity(selectedIconIndex != nil ? 0 : 1)
        }
    }

    @ViewBuilder private var thankYouView: some View {
        if !animationsFinished {
            VStack(spacing: 20) {
                Spacer()

                SubscriptionBadge(tier: .patron)
                    .scaleEffect(1.2)

                Text(L10n.patronThankYou)
                    .font(style: .title, weight: .bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)

                HighlightedText(L10n.patronUnlockInstructions)
                    .highlight(L10n.patronUnlockWord, { highlight in
                            .init(weight: .bold, color: Color.patronBackgroundColor)
                    })
                    .font(style: .subheadline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)

                // Unlock / Skip Buttons
                VStack(spacing: 5) {
                    PatronUnlockButton {
                        unlockProgress = 1
                        isUnlocked = true
                    } onProgress: { progress in
                        unlockProgress = progress
                    }

                    Button(L10n.plusSkip) {
                        viewModel.continueTapped()
                    }
                    .buttonStyle(SimpleTextButtonStyle(theme: .init(previewTheme: .contrastLight)))
                }

                Spacer()
            }

            // When finished have the view spring towards the user and disappear
            .scaleEffect(isUnlocked ? 5 : 1)
            .opacity(isUnlocked ? 0 : 1)
            .accessibilityAnimation(.default.speed(2.5), value: isUnlocked)
        }
    }

    // Displays the app icons view
    @ViewBuilder private var iconsView: some View {
        if !isSmallScreen {
            Spacer()
        }

        VStack(spacing: -75) {
            let icons = viewModel.icons

            ForEach(0..<icons.count, id: \.self) { index in
                let imageName = icons[index].previewIconName

                AnimatedAppIconImage(imageName: imageName, index: index, visible: isUnlocked, onAppear: {
                    // Don't replay if we've already finished
                    guard !animationsFinished else { return }

                    if !reduceMotion {
                        haptics.slam()
                    }

                    if index == icons.count-1 {
                        animationsFinished = true
                    }
                }, onTap: {
                    withAccessibilityAnimation(PatronConstants.iconTapAnimation) {
                        selectedIconIndex = index
                    }
                })
                .matchedGeometryEffect(id: "icon_\(index)", in: namespace)
            }
        }
        .accessibilityTransition (
            .scale.combined(with: .opacity).animation(PatronConstants.iconTapAnimation)
        )
    }

    // App icon selection / prevent
    @ViewBuilder private var selectedIconView: some View {
        if let selectedIconIndex {
            let icon = viewModel.icons[selectedIconIndex]

            SelectedAppIconImage(namespace: namespace,
                                 index: selectedIconIndex,
                                 imageName: icon.previewIconName)

            VStack(spacing: 5) {
                Button(L10n.changeAppIcon) {
                    viewModel.iconSelected(icon)
                }
                .buttonStyle(PlusGradientFilledButtonStyle(plan: .patron))

                Button(L10n.back) {
                    withAccessibilityAnimation(PatronConstants.iconTapAnimation) {
                        self.selectedIconIndex = nil
                    }
                }
                .buttonStyle(SimpleTextButtonStyle(theme: .init(previewTheme: .contrastLight)))
            }
        }
    }
}

private enum PatronConstants {
    static let iconTapAnimation: Animation = .interpolatingSpring(stiffness: 500,
                                                                  damping: 35,
                                                                  initialVelocity: 1)

    // Delay when we start animating
    static let appearDelay: TimeInterval = 0.5

    // The amount of time before each image animates in
    static let delay: TimeInterval = 0.25
}

// MARK: - App Icon Views

/// Renders the basic app icon preview
private struct AppIconImage: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .cornerRadius(20)

            // 2 shadows to allow the icon to appear over darker icons and adds a nice glow
            .shadow(color: .black.opacity(0.5), radius: 10)
            .shadow(color: .white.opacity(0.4), radius: 10)
    }
}

/// The image used when displaying a selection, contains some parallax and glossy effects
private struct SelectedAppIconImage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateRotation = false
    @State private var contentSize: CGSize = .zero

    let namespace: Namespace.ID
    let index: Int
    let imageName: String

    private var rotationDegrees: Double {
        (index % 2 == 0) ? -5.0 : 5.0
    }

    var body: some View {
        ContentSizeReader(contentSize: $contentSize) {
            glossyEffect {
                AppIconImage(imageName: imageName)
                    .rotationEffect(.degrees(animateRotation ? rotationDegrees * -1 : rotationDegrees))
                    .accessibilityAnimation(PatronConstants.iconTapAnimation.speed(0.9), value: animateRotation)
                    .modifier(IconParallaxModifier())
                    .scaleEffect(1.2)
            }
        }
        // Adjust the padding
        .padding(.vertical, max(contentSize.height * 0.4, 55))
    }

    @ViewBuilder
    private func glossyEffect<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        if reduceMotion {
            content()
        } else {
            GlossyEffect {
                content()
            }
            .onAppear { animateRotation = true }
            .matchedGeometryEffect(id: "icon_\(index)", in: namespace)
        }
    }
}

/// An image that falls from down and slams in
private struct AnimatedAppIconImage: View {
    let imageName: String
    let index: Int
    let visible: Bool

    /// Triggered when the icon finished animating in
    var onAppear: () -> Void

    /// Triggered when the user taps an app icon
    var onTap: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AppIconImage(imageName: imageName)
            .onLongPressGesture(minimumDuration: 1) {} onPressingChanged: { pressed in
                isPressed = pressed

                if !pressed {
                    onTap()
                }
            }
            .applyButtonEffect(isPressed: isPressed)

            // Stagger the icons
            .offset(x: (index % 2 == 0) ? -50 : 50)
            .rotationEffect(.degrees(((index % 2 == 0) ? -10 : 5)))

            // Appear animation, we start with a super enlarged version and "slam" that down as we scale
            // to 1 and have the icon appear
            .scaleEffect(visible ? 1 : 5)
            .opacity(visible ? 1 : 0)
            .accessibilityAnimation(animation, value: visible)
            .overlay(Action {
                guard visible else { return }

                // Trigger the on appear block once the image has animated in
                DispatchQueue.main.asyncAfter(deadline: .now() + delay()) {
                    onAppear()
                }
            })
    }

    /// Delays each app icon briefly so they fall one after another
    private func delay() -> TimeInterval {
        (Double(index) * PatronConstants.delay) + PatronConstants.appearDelay
    }

    private var animation: Animation? {
        // Use a fast appearing spring animation to simulate a slam
       .interpolatingSpring(stiffness: 750, damping: 37, initialVelocity: 1)
       .speed(1.75)
       .delay(delay())
    }
}

// MARK: - PatronUnlockHaptics

/// Helper class to perform the animations
/// We use an `ObservableObject` so we can use `@StateObject` to prevent recreating the object when SwiftUI rerenders
private class PatronIconHaptics: ObservableObject {
    private let haptics: HapticsProxy? = .init()

    func slam() {
        haptics?.slam()
    }

    func spring() {
        haptics?.spring()
    }

    func confetti() {
        haptics?.confetti()
    }

    /// Internal proxy struct that can return nil since an `@StateObject` can't be nil
    private struct HapticsProxy {
        private let engine: CHHapticEngine
        private let slamFile: URL
        private let springFile: URL

        init?() {
            // don't setup unless haptics are supported and the files are available
            guard
                CHHapticEngine.capabilitiesForHardware().supportsHaptics,
                let slamFile = Bundle.main.url(forResource: "Slam", withExtension: "ahap"),
                let springFile = Bundle.main.url(forResource: "Spring", withExtension: "ahap"),
                let engine = try? CHHapticEngine()
            else {
                return nil
            }

            self.slamFile = slamFile
            self.springFile = springFile
            self.engine = engine

            // Prepare the haptics engine
            try? engine.start()
        }

        func slam() {
            try? engine.playPattern(from: slamFile)
        }

        func spring() {
            try? engine.playPattern(from: springFile)
        }

        func confetti() {
            var events: [CHHapticEvent] = []

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

            guard
                let pattern = try? CHHapticPattern(events: events, parameters: []),
                let player = try? engine.makePlayer(with: pattern)
            else {
                return
            }

            try? player.start(atTime: 0)
        }
    }
}

// MARK: - Icon Card Parallax Modifier

/// Adds a subtle parallax effect to the app icon as the user tilts their device
private struct IconParallaxModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var manager: MotionManager = .init()

    func body(content: Content) -> some View {
        let roll = manager.roll * 10
        let pitch = manager.pitch
        content
            .offset(x: roll, y: pitch * 10)
            .rotation3DEffect(.degrees(roll), axis: (0, 1, 0), perspective: 1)
            .rotation3DEffect(.degrees(pitch * 3), axis: (1, 0, 0), perspective: 1)
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

// MARK: - Previews
struct PatronAppIconUnlock_Previews: PreviewProvider {
    static var previews: some View {
        PatronAppIconUnlock(viewModel: .init())
    }
}
