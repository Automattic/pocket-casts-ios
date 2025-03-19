import Foundation
import ActivityKit

@available(iOS 16.2, *)
class SleepTimerLiveActivityManager {
    static let shared = SleepTimerLiveActivityManager()
    private var activity: Activity<SleepTimerLiveActivityAttributes>?
    private var sleepTimerTimeInterval: TimeInterval = -1

    private init() {}

    func setSleepTimerInterval(_ interval: TimeInterval) {
        sleepTimerTimeInterval = interval
    }

    func startActivity(currentTime: TimeInterval) {
        if activity != nil {
            return
        }
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let progress = Double(currentTime) / sleepTimerTimeInterval
            let attributes = SleepTimerLiveActivityAttributes()
            let state = SleepTimerLiveActivityAttributes.SleepTimerLiveStatus(currentTime: currentTime, progress: progress)
            do {
                activity = try Activity<SleepTimerLiveActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                print("Live activity started")
            } catch {
                print("Failed to start live activity: \(error)")
            }
        }
    }

    func updateActivity(currentTime: TimeInterval) {
        guard let activity = activity else { return }

        let progress = Double(currentTime) / Double(sleepTimerTimeInterval)
        let state = SleepTimerLiveActivityAttributes.SleepTimerLiveStatus(currentTime: currentTime, progress: progress)

        Task {
            await activity.update(using: state)
            print("Live Activity updated currentTime: \(currentTime).")
        }
    }

    func endActivity(currentTime: TimeInterval) {
        guard let activity = activity else { return }

        let progress = Double(currentTime) / Double(sleepTimerTimeInterval)
        let state = SleepTimerLiveActivityAttributes.SleepTimerLiveStatus(currentTime: currentTime, progress: progress)

        Task { [weak self] in
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
            print("Live Activity ended.")
            self?.activity = nil
        }
    }
}
