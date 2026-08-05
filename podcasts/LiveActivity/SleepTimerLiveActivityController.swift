import ActivityKit
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

@available(iOS 17.0, *)
final class SleepTimerLiveActivityController {
    static let shared = SleepTimerLiveActivityController()

    private init() {}

    func startTimer(duration: TimeInterval, episode: BaseEpisode?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = SleepTimerActivityAttributes(startedAt: Date())
        let content = content(remaining: duration, isPaused: false, episode: episode)

        Task {
            await endAllActivities(dismissalPolicy: .immediate)

            do {
                _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                FileLog.shared.addMessage("Sleep Timer Live Activity: unable to start activity: \(error)")
            }
        }
    }

    /// Pushes the current state of the sleep timer to any running activity. Called whenever
    /// playback pauses or resumes, the episode changes, or the timer is extended.
    func sync(remaining: TimeInterval, isPaused: Bool, episode: BaseEpisode?) {
        let content = content(remaining: remaining, isPaused: isPaused, episode: episode)

        Task {
            for activity in Activity<SleepTimerActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    /// The sleep timer only lives in memory, so an activity can outlive it if the app is
    /// force quit. Reap anything that no longer matches the app's state.
    func reconcile(isTimerRunning: Bool, remaining: TimeInterval, isPaused: Bool, episode: BaseEpisode?) {
        guard isTimerRunning else {
            endAll()
            return
        }

        sync(remaining: remaining, isPaused: isPaused, episode: episode)
    }

    func endAll(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
        Task {
            await endAllActivities(dismissalPolicy: dismissalPolicy)
        }
    }

    private func content(remaining: TimeInterval, isPaused: Bool, episode: BaseEpisode?) -> ActivityContent<SleepTimerActivityAttributes.ContentState> {
        let timerEndDate = Date().addingTimeInterval(remaining)
        let state = SleepTimerActivityAttributes.ContentState(
            timerEndDate: timerEndDate,
            remaining: remaining,
            isPaused: isPaused,
            episodeTitle: episode?.displayableTitle(),
            podcastTitle: episode?.subTitle()
        )

        // A paused timer never goes stale, it's just waiting for playback to resume.
        return ActivityContent(state: state, staleDate: isPaused ? nil : timerEndDate, relevanceScore: 1)
    }

    private func endAllActivities(dismissalPolicy: ActivityUIDismissalPolicy) async {
        for activity in Activity<SleepTimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
        }
    }
}
