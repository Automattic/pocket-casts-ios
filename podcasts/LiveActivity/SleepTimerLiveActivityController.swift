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

        let timerEndDate = Date().addingTimeInterval(duration)
        let attributes = SleepTimerActivityAttributes(
            startedAt: Date(),
            episodeTitle: episode?.displayableTitle(),
            podcastTitle: episode?.subTitle()
        )
        let content = ActivityContent(
            state: SleepTimerActivityAttributes.ContentState(timerEndDate: timerEndDate),
            staleDate: timerEndDate,
            relevanceScore: 1
        )

        Task {
            await endAllActivities(dismissalPolicy: .immediate)

            do {
                _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                FileLog.shared.addMessage("Sleep Timer Live Activity: unable to start activity: \(error)")
            }
        }
    }

    func updateTimer(durationRemaining: TimeInterval) {
        let timerEndDate = Date().addingTimeInterval(durationRemaining)
        let content = ActivityContent(
            state: SleepTimerActivityAttributes.ContentState(timerEndDate: timerEndDate),
            staleDate: timerEndDate,
            relevanceScore: 1
        )

        Task {
            for activity in Activity<SleepTimerActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    func endAll(dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        Task {
            await endAllActivities(dismissalPolicy: dismissalPolicy)
        }
    }

    private func endAllActivities(dismissalPolicy: ActivityUIDismissalPolicy) async {
        for activity in Activity<SleepTimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
        }
    }
}
