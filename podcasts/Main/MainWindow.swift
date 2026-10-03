import UIKit

/// The app's main window. It keeps track of when the screen was last touched, so a prompt that
/// shouldn't land under someone's finger can wait for a quiet moment.
final class MainWindow: UIWindow {
    private var isTouching = false

    /// When the last touch event arrived, on the same clock as `ProcessInfo.systemUptime`
    private var lastTouchTimestamp: TimeInterval?

    /// Whether a finger is on the screen now, or was within the last `interval` seconds
    func wasTouched(inLast interval: TimeInterval) -> Bool {
        if isTouching {
            return true
        }
        guard let lastTouchTimestamp else {
            return false
        }
        return ProcessInfo.processInfo.systemUptime - lastTouchTimestamp < interval
    }

    override func sendEvent(_ event: UIEvent) {
        if event.type == .touches, let touches = event.touches(for: self), !touches.isEmpty {
            isTouching = touches.contains { $0.phase != .ended && $0.phase != .cancelled }
            lastTouchTimestamp = event.timestamp
        }
        super.sendEvent(event)
    }
}
