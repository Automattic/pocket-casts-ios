import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SleepTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let timerEndDate: Date
    }

    let startedAt: Date
    let episodeTitle: String?
    let podcastTitle: String?
}
