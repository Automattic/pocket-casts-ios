import ActivityKit
import Foundation
import PocketCastsUtils

final class SleepTimerLiveActivityController {
    static let shared = SleepTimerLiveActivityController()

    /// The activity this launch requested. `Activity.activities` is eventually consistent and
    /// doesn't include an activity the moment it's returned by `request`, so neither updating nor
    /// ending can rely on that array alone.
    private var requestedActivity: Activity<SleepTimerActivityAttributes>?

    /// Every ActivityKit call is async, so each entry point has to hand its work to a `Task`.
    /// Independent tasks have no ordering guarantee and these operations don't commute, so they're
    /// chained to run in the order they were requested.
    private var pendingWork = Task<Void, Never> {}
    private let lock = NSLock()

    private init() {}

    func startTimer(duration: TimeInterval) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = SleepTimerActivityAttributes()
        let content = content(remaining: duration, isPaused: false)

        enqueue {
            await self.endActivities(dismissalPolicy: .immediate)

            do {
                self.requestedActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                FileLog.shared.addMessage("Sleep Timer Live Activity: unable to start activity: \(error)")
            }
        }
    }

    /// Pushes the current state of the sleep timer to any running activity. Called whenever
    /// playback pauses or resumes, or the timer is extended.
    func sync(remaining: TimeInterval, isPaused: Bool) {
        let content = content(remaining: remaining, isPaused: isPaused)

        enqueue {
            for activity in self.activities {
                await activity.update(content)
            }
        }
    }

    /// The sleep timer only lives in memory, so an activity can outlive it if the app is
    /// force quit. Reap anything that no longer matches the app's state.
    func reconcile(isTimerRunning: Bool, remaining: TimeInterval, isPaused: Bool) {
        guard isTimerRunning else {
            endAll()
            return
        }

        sync(remaining: remaining, isPaused: isPaused)
    }

    func endAll(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
        enqueue {
            await self.endActivities(dismissalPolicy: dismissalPolicy)
        }
    }

    /// Runs `work` once everything already enqueued has finished. Callable from any thread; the
    /// work itself always runs on the main actor, so it's the only place that touches our state.
    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let previous = pendingWork
        pendingWork = Task { @MainActor in
            await previous.value
            await work()
        }
    }

    /// Activities left behind by a previous launch come from `Activity.activities`; one requested a
    /// moment ago may only be in `requestedActivity`.
    @MainActor
    private var activities: [Activity<SleepTimerActivityAttributes>] {
        var activities = Activity<SleepTimerActivityAttributes>.activities
        if let requestedActivity, !activities.contains(where: { $0.id == requestedActivity.id }) {
            activities.append(requestedActivity)
        }

        return activities
    }

    private func content(remaining: TimeInterval, isPaused: Bool) -> ActivityContent<SleepTimerActivityAttributes.ContentState> {
        let timerEndDate = Date().addingTimeInterval(remaining)
        let state = SleepTimerActivityAttributes.ContentState(
            timerEndDate: timerEndDate,
            remaining: remaining,
            isPaused: isPaused
        )

        // A paused timer never goes stale, it's just waiting for playback to resume.
        return ActivityContent(state: state, staleDate: isPaused ? nil : timerEndDate, relevanceScore: 1)
    }

    @MainActor
    private func endActivities(dismissalPolicy: ActivityUIDismissalPolicy) async {
        for activity in activities {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
        }

        requestedActivity = nil
    }
}
