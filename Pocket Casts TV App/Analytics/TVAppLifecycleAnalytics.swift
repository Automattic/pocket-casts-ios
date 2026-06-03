import Foundation
import SwiftUI

/// Tracks application opened/closed analytics events driven by SwiftUI scene phase changes.
///
/// The TV app uses the SwiftUI app lifecycle (no `AppDelegate`), so we observe
/// `scenePhase` rather than `UIApplication` notifications. The behaviour mirrors
/// the iOS app's `AppLifecycleAnalytics`: `.applicationOpened` is tracked when the
/// app becomes active (guarded so it only fires once per foreground session) and
/// `.applicationClosed` is tracked when the app enters the background, including
/// how long it was open.
@MainActor
final class TVAppLifecycleAnalytics {
    static let shared = TVAppLifecycleAnalytics()

    /// The date the app was last opened, used both as a guard against duplicate
    /// open events and to calculate the time spent in the app.
    private var applicationOpenedTime: Date?

    func handle(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            didBecomeActive()
        case .background:
            didEnterBackground()
        default:
            break
        }
    }

    private func didBecomeActive() {
        // Avoid firing again when returning from a transient `.inactive` state
        // (e.g. a system overlay) without having entered the background.
        guard applicationOpenedTime == nil else { return }

        applicationOpenedTime = Date()
        Analytics.track(.applicationOpened)
    }

    private func didEnterBackground() {
        var properties: [String: Any] = [:]

        if let openTime = applicationOpenedTime {
            let timeInApp = round(Date().timeIntervalSince(openTime))
            properties = ["time_in_app": timeInApp.description]
        }

        Analytics.track(.applicationClosed, properties: properties)
        applicationOpenedTime = nil
    }
}
