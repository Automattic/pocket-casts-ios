import SwiftUI

class PlayPauseAnimationViewModel: ObservableObject {
    @Published private(set) var paused = true

    private var duration: TimeInterval

    init(duration: TimeInterval) {
        self.duration = duration
    }

    func animate(_ value: Binding<Double>, to: Double) -> PlayPauseAnimatableModifier {
        return PlayPauseAnimatableModifier(value: value, to: to, duration: duration, viewModel: self)
    }

    func play() {
        paused = false
    }

    func pause() {
        paused = true
    }
}

struct PlayPauseAnimatableModifier: AnimatableModifier {
    @ObservedObject private var viewModel: PlayPauseAnimationViewModel

    @Binding private var value: Double
    private var currentValue: Double
    private var finalValue: Double

    private var duration: TimeInterval

    @State private var paused: Bool = true

    @State private var startTime: Date?

    @State private var remainingTime: TimeInterval = 0

    var animatableData: Double {
        get { currentValue }
        set { currentValue = newValue }
    }

    init(value: Binding<Double>, to finalValue: Double, duration: TimeInterval, viewModel: PlayPauseAnimationViewModel) {
        self._value = value
        self.currentValue = value.wrappedValue
        self.finalValue = finalValue
        self.duration = duration
        self._remainingTime = State(initialValue: duration)
        self.viewModel = viewModel
    }

    func body(content: Content) -> some View {
        content
            .onReceive(viewModel.$paused) {
                paused = $0
                playOrPause()
            }
    }

    private func playOrPause() {
        paused ? pause() : play()
    }

    private func pause() {
        remainingTime += startTime?.timeIntervalSinceNow ?? 0
        withAnimation(.linear(duration: 0)) {
            value = currentValue
        }
    }

    private func play() {
        startTime = Date()
        withAnimation(.linear(duration: remainingTime)) {
            value = finalValue
        }
    }
}
