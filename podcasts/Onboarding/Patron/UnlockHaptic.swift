import Foundation
import CoreHaptics

/// A dynamic haptic that plays over the course of a duration and increases with intensity the closer to the end
///
final class UnlockHaptic: ObservableObject {
    let duration: TimeInterval

    private let engine: CHHapticEngine?
    private var events: [CHHapticEvent] = []
    private var player: CHHapticPatternPlayer? = nil

    init(duration: TimeInterval) {
        self.duration = duration

        // don't setup unless haptics are supported
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            self.engine = nil
            return
        }

        self.engine = try? CHHapticEngine()
        try? self.engine?.start()

        build()
    }

    func play() {
        try? engine?.start()
        try? player?.start(atTime: CHHapticTimeImmediate)
    }

    func stop() {
        engine?.stop()
    }

    private func build() {
        // Continuous rumble
        addRumble()

        // Add some knocks to amplify intensity
        addKnocks()

        // 🏃‍♀️ You start walking
        addMediumHeartBeats()

        // 🏃‍♂️🏃‍♂️ You're jogging at a brisk pace
        addFastHeartBeats()

        // I AM SPRINTING AS FAST AS I CAN 🏃‍♂️🏃‍♂️🏃‍♂️🏃‍♂️💨💨💨
        addReallyFastHeartBeats()

        guard let pattern = try? CHHapticPattern(events: events, parameters: []) else {
            return
        }

        player = try? engine?.makePlayer(with: pattern)
    }

    private func addKnocks() {
        for time in stride(from: duration * 0.5, to: duration * 10, by: 0.1) {
            events.append(.init(type: .hapticTransient, intensity: 1, sharpness: 1, startTime: time))
        }
    }

    private func addMediumHeartBeats() {
        for time in stride(from: duration * 0.5, to: duration * 0.8, by: 0.4) {
            addHeartBeats(startTime: time)
        }
    }

    private func addFastHeartBeats() {
        for time in stride(from: duration * 0.8, to: duration * 0.9, by: 0.3) {
            addHeartBeats(startTime: time)
        }
    }

    private func addReallyFastHeartBeats() {
        for time in stride(from: duration * 0.9, to: duration * 10, by: 0.2) {
            addHeartBeats(startTime: time)
        }
    }

    private func addRumble() {
        events.append(.init(type: .hapticContinuous, intensity: 0.2, sharpness: 0.5, startTime: 0, duration: .infinity))
    }

    private func addHeartBeats(startTime: TimeInterval) {
        let progress = Float(startTime / duration)

        events += [
            .init(type: .hapticTransient, intensity: 0.8 * progress, sharpness: 0.2, startTime: startTime),
            .init(type: .hapticTransient, intensity: 1.0 * progress, sharpness: 0.3, startTime: startTime + 0.015),
            .init(type: .hapticTransient, intensity: 0.8 * progress, sharpness: 0.1, startTime: startTime + 0.2),
            .init(type: .hapticTransient, intensity: 0.8 * progress, sharpness: 0.0, startTime: startTime + 0.25),
        ]
    }
}

private extension CHHapticEvent {
    convenience init(type: EventType, intensity: Float, sharpness: Float, startTime: TimeInterval, duration: TimeInterval? = nil) {
        let parameters: [CHHapticEventParameter] = [
            .init(parameterID: .hapticIntensity, value: intensity),
            .init(parameterID: .hapticSharpness, value: sharpness)
        ]

        guard let duration else {
            self.init(eventType: type, parameters: parameters, relativeTime: startTime)
            return
        }

        self.init(eventType: type, parameters: parameters, relativeTime: startTime, duration: duration)
    }
}
