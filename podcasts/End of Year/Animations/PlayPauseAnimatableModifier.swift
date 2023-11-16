import SwiftUI

class PlayPauseAnimationViewModel: ObservableObject {
    @Published private(set) var paused = true

    private var duration: TimeInterval

    private let animationType: (TimeInterval) -> Animation

    init(duration: TimeInterval, animation: @escaping (TimeInterval) -> Animation = Animation.linear(duration:)) {
        self.duration = duration
        self.animationType = animation
    }


    /// Adds a modifier that will animates the given View
    /// - Parameters:
    ///   - value: the value to bind to
    ///   - to: the final value of the property
    ///   - after: how long the animation should wait before starting
    /// - Returns: PlayPauseAnimatableModifier
    func animate(_ value: Binding<Double>, to: Double, after: Double = 0) -> PlayPauseAnimatableModifier {
        return PlayPauseAnimatableModifier(value: value, to: to, duration: duration, viewModel: self, animation: animationType, after: after)
    }

    func play() {
        guard paused else {
            return
        }

        paused = false
    }

    func pause() {
        guard !paused else {
            return
        }

        paused = true
    }
}

struct PlayPauseAnimatableModifier: AnimatableModifier {
    @ObservedObject private var viewModel: PlayPauseAnimationViewModel

    @Binding private var value: Double
    private var currentValue: Double
    private var finalValue: Double

    private var duration: TimeInterval
    private let animationType: (TimeInterval) -> Animation

    @State private var paused: Bool = true

    @State private var startTime: Date?

    @State private var remainingTime: TimeInterval = 0

    @State private var after: Double = 0

    @State private var timer: Timer?

    var animatableData: Double {
        get { currentValue }
        set { currentValue = newValue }
    }

    init(value: Binding<Double>, to finalValue: Double, duration: TimeInterval, viewModel: PlayPauseAnimationViewModel, animation: @escaping (TimeInterval) -> Animation = Animation.linear(duration:), after: Double) {
        self._value = value
        self.currentValue = value.wrappedValue
        self.finalValue = finalValue
        self.duration = duration
        self._remainingTime = State(initialValue: duration)
        self.viewModel = viewModel
        self.animationType = animation
        self._after = State(initialValue: after)
    }

    func body(content: Content) -> some View {
        content
            .onReceive(viewModel.$paused) {
                paused = $0
                playOrPause()
            }
    }

    private func playOrPause() {
        if timer?.isValid == true || after > 0 {
            paused ? pauseTimer() : startTimer()
            return
        }

        paused ? pause() : play()
    }

    private func pause() {
        guard let startTime else {
            return
        }

        remainingTime += startTime.timeIntervalSinceNow
        withAnimation(.linear(duration: 0)) {
            value = currentValue
        }
    }

    private func play() {
        startTime = Date()
        withAnimation(animationType(remainingTime)) {
            value = finalValue
        }
    }

    private func pauseTimer() {
        guard let timer else {
            return
        }

        after = timer.fireDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
        timer.invalidate()
    }

    private func startTimer() {
        timer = Timer(fire: Date.now + after, interval: 0, repeats: false) { timer in
            after = 0
            timer.invalidate()
            play()
        }
        RunLoop.current.add(timer!, forMode: .default)
    }
}

extension Animation {
    static func spring(_ duration: TimeInterval) -> Animation {
        return spring(duration: duration, bounce: 0.3)
    }
}
