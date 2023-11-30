import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    /// A number representing how much the user how tilted the device side to side
    @Published var pitch: Double = 0

    /// A number representing how much the device is being tilted up and down
    @Published var roll: Double = 0

    /// A number representing how much the user had the device tilted side to side
    /// when the motion updates started
    @Published var initialPitch: Double?

    /// A number representing how much the user had the device tilted up and down
    /// when the motion updates started
    @Published var initialRoll: Double?

    // Gravity values
    @Published var x: Double = 0
    @Published var y: Double = 0
    @Published var z: Double = 0

    private var motionManager: CMMotionManager
    let options: MotionOptions
    private let relativeToWhenStarting: Bool


    /// Creates an ObservableObject that published changes on the device motion
    /// - Parameters:
    ///   - options: whether it should take into account only attitude, gravity or all
    ///   - relativeToWhenStarting: if set to `true` the values will be relative to when the motion started. Ie.: they will be subtracted from the final value
    init(options: MotionOptions = .all, relativeToWhenStarting: Bool = false) {
        self.options = options
        self.motionManager = CMMotionManager()
        self.relativeToWhenStarting = relativeToWhenStarting
    }

    func start() {
        // Don't try to setup unless motion is available
        guard self.motionManager.isDeviceMotionAvailable else { return }

        self.motionManager.stopDeviceMotionUpdates()

        self.motionManager.deviceMotionUpdateInterval = Config.updateInterval
        self.motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
            guard let data else { return }

            self.update(data)
        }
    }

    func stop() {
        self.motionManager.stopDeviceMotionUpdates()
        initialPitch = nil
        initialRoll = nil
    }

    private func update(_ data: CMDeviceMotion) {
        if options.contains(.attitude) {
            let attitude = data.attitude

            if !attitude.pitch.isNaN && !attitude.roll.isNaN {
                let gz = data.gravity.z
                let pitch = attitude.pitch
                let roll = attitude.roll

                if relativeToWhenStarting && initialRoll == nil && initialPitch == nil {
                    initialPitch = pitch
                    initialRoll = roll
                }

                self.pitch = pitch - (initialPitch ?? 0)
                self.roll = roll - (initialRoll ?? 0)
            }
        }

        if options.contains(.gravity) {
            let gravity = data.userAcceleration
            (x, y, z) = (gravity.x, gravity.y, gravity.z)
        }

        self.objectWillChange.send()
    }

    private func adjustValueForUpsideDown(_ value: Double, gravityZ: Double) -> Double {
        // Gravity Z will be less than 0 when the device is near upside down
        guard gravityZ > 0 else {
            return value
        }

        return value > 0 ? .pi - value : -(.pi + value)
    }

    struct MotionOptions: OptionSet {
        let rawValue: Int
        static let attitude = MotionOptions(rawValue: 1 << 0)
        static let gravity  = MotionOptions(rawValue: 2 << 0)

        static let all: MotionOptions = [.attitude, .gravity]
    }

    private enum Config {
        /// Update at 60fps
        static let updateInterval: TimeInterval = 1/60
    }
}
