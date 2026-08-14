import ActivityKit
import Foundation

struct SleepTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the timer will fire. Only rendered while playback is running; a paused timer
        /// renders `remaining` statically instead.
        let timerEndDate: Date

        /// How much time is left on the timer. The sleep timer only counts down while
        /// playback is running, so this lets the widget freeze rather than run to zero.
        let remaining: TimeInterval

        let isPaused: Bool
    }
}
