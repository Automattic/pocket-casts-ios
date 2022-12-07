import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    /// A number representing how much the user how tilted the device side to side
    @Published var pitch: Double = 0

    /// A number representing how much the device is being tilted up and down
    @Published var roll: Double = 0

    // Gravity values
    @Published var x: Double = 0
    @Published var y: Double = 0
    @Published var z: Double = 0

    private var motionManager: CMMotionManager
    let options: MotionOptions

    init(options: MotionOptions = .all) {
        self.options = options
        self.motionManager = CMMotionManager()
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
    }

    private func update(_ data: CMDeviceMotion) {
        if options.contains(.attitude) {
            let attitude = data.attitude

            if !attitude.pitch.isNaN && !attitude.roll.isNaN {
                let gz = data.gravity.z
                let pitch = adjustValueForUpsideDown(attitude.pitch, gravityZ: gz)
                let roll = adjustValueForUpsideDown(attitude.roll, gravityZ: gz)

                self.pitch = pitch
                self.roll = roll
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
