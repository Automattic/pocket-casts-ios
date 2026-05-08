#if os(tvOS)
class BackgroundShakeObserver {
    var whenShook: (() -> Void)?

    func stopObserving() {

    }
}
#else
import CoreMotion

class BackgroundShakeObserver {
    private let manager = CMMotionManager()
    private let motionUpdateInterval: Double = 0.05
    private var debounceTimer: Timer?
    var whenShook: (() -> Void)?

    init() {
        #if !os(watchOS) && !APPCLIP
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sleepTimerChanged), name: Constants.Notifications.sleepTimerChanged, object: nil)
        #endif
    }

    @objc private func appMovedToBackground() {
        if PlaybackManager.shared.sleepTimerActive() && Settings.shakeToRestartSleepTimer {
            startObserving()
        }
    }

    @objc private func appMovedToForeground() {
        stopObserving()
    }

    @objc private func sleepTimerChanged() {
        if !PlaybackManager.shared.sleepTimerActive() {
            stopObserving()
        }
    }

    func startObserving() {
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = motionUpdateInterval

            manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let data else {
                    return
                }

                if (abs(data.userAcceleration.y) > 0.8
                    || abs(data.userAcceleration.x) > 0.8)
                    && abs(data.userAcceleration.z) < 0.2 {
                    self?.debounceTimer?.invalidate()
                    self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
                        self?.whenShook?()
                    }
                }

            }
        }
    }

    func stopObserving() {
        manager.stopDeviceMotionUpdates()
    }
}
#endif
