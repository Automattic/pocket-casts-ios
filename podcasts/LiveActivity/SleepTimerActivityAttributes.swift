import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SleepTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the timer will fire. While paused this is only used to derive nothing:
        /// `remaining` is the source of truth and the UI renders it statically.
        let timerEndDate: Date

        /// How much time is left on the timer. The sleep timer only counts down while
        /// playback is running, so this lets the widget freeze rather than run to zero.
        let remaining: TimeInterval

        let isPaused: Bool

        /// These live here rather than in the attributes so they can follow the episode
        /// while the timer runs. `ActivityAttributes` are fixed for the life of an activity.
        let episodeTitle: String?
        let podcastTitle: String?
    }

    let startedAt: Date
}
