import SwiftUI

// This code belongs to Artem M
// https://medium.com/@artemiusm/how-to-pause-and-resume-animation-in-swiftui-with-chaining-68003517449f
// https://github.com/artemiusmk/MovieClapper
class PauseModifierManager: ObservableObject {

    @Published private (set) var paused = true
    @Published var currentTime = 0.0
    private var playStartedTime = 0.0
    private var playStartedDate: Date?
    private var animationsStartTime: Set<Double> = []
    private var maxTime: Double
    private var task: DispatchWorkItem?

    init(maxTime: Double, additionalTimeUpdates: [Double] = []) {
        self.maxTime = maxTime
        animationsStartTime.insert(maxTime)
        animationsStartTime.formUnion(additionalTimeUpdates)
    }

    func modifier(
        propertyValue: Binding<Double>,
        propertyFinalValue: Double,
        startTime: Double,
        endTime: Double
    ) -> PauseModifier {
        // at 0 time we usually reset animations,
        // so to avoid collisions of property values let's set min startTime to 0.1
        let startTime = max(0.1, startTime)

        // If a new animation starts earlier than the next one that was added earlier,
        // we must update the schedule
        if !paused, startTime > currentTime, (nextStartTime ?? 0) > startTime {
            animationsStartTime.insert(startTime)
            task?.cancel()
            scheduleCurrentTimeUpdate()
        } else {
            animationsStartTime.insert(startTime)
        }
        return PauseModifier(
            propertyValue: propertyValue,
            propertyFinalValue: propertyFinalValue,
            startTime: startTime,
            endTime: endTime,
            manager: self
        )
    }

    func togglePaused() {
        paused.toggle()
        if paused {
            task?.cancel()
            updateCurrentTime()
        } else {
            playStartedDate = Date()
            playStartedTime = currentTime
            scheduleCurrentTimeUpdate()
        }
    }

    private func scheduleCurrentTimeUpdate() {
        // kind of autoplay, we can disable (pause) it here
        if currentTime >= maxTime {
            seekToBegining()
        }

        guard !paused, let nextStartTime = nextStartTime else { return }

        task = DispatchWorkItem { [weak self] in
            self?.updateCurrentTime()
            self?.scheduleCurrentTimeUpdate()
        }
        if let task = task {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + nextStartTime - currentTime,
                execute: task
            )
        }
    }

    private func updateCurrentTime() {
        currentTime = playStartedTime + abs(playStartedDate?.timeIntervalSinceNow ?? 0)
    }

    private func seekToBegining() {
        playStartedDate = Date()
        playStartedTime = 0
        currentTime = 0
    }

    private var nextStartTime: Double? {
        animationsStartTime.sorted().first { $0 > currentTime }
    }
}

struct PauseModifier: AnimatableModifier {

    @ObservedObject private var manager: PauseModifierManager
    @Binding private var propertyValue: Double
    private var propertyFinalValue: Double
    private var startTime: Double
    private var endTime: Double
    @State private var currentTime: Double = 0
    @State private var paused: Bool = true
    @State private var animationPaused = true
    private var propertyCurrentValue: Double

    init(propertyValue: Binding<Double>,
         propertyFinalValue: Double,
         startTime: Double,
         endTime: Double,
         manager: PauseModifierManager
    ) {
        self._propertyValue = propertyValue
        self.propertyFinalValue = propertyFinalValue
        self.startTime = startTime
        self.endTime = endTime
        self.propertyCurrentValue = propertyValue.wrappedValue
        self.manager = manager
    }

    var animatableData: Double {
        get { propertyCurrentValue }
        set { propertyCurrentValue = newValue }
    }

    func body(content: Content) -> some View {
        content
            .onReceive(manager.$paused) {
                paused = $0
                updateAnimation()
            }
            .onReceive(manager.$currentTime) {
                currentTime = $0
                resetIfNeeded()
                updateAnimation()
            }
    }

    private func updateAnimation() {
        // animationPaused is internal flag of this modifier
        // needed to avoid running the same animation multiple times in a row
        guard currentAnimationTimeFrame, animationPaused != paused else { return }
        animationPaused.toggle()
        if paused {
            // Stop animation
            withAnimation(.linear(duration: 0)) {
                propertyValue = propertyCurrentValue
            }
        } else {
            // Continue animation
            // .easeInOut animation can be replaced by another animation
            withAnimation(.linear(duration: remainingTime)) {
                propertyValue = propertyFinalValue
            }
        }
    }

    private var remainingTime: Double {
        endTime - currentTime
    }

    private var currentAnimationTimeFrame: Bool {
        startTime <= currentTime && currentTime < endTime
    }

    private func resetIfNeeded() {
        if !currentAnimationTimeFrame {
            animationPaused = true
        }
    }
}
