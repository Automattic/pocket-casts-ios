import Foundation
import ActivityKit
import WidgetKit

@available(iOS 16.2, *)
struct SleepTimerLiveActivityAttributes: ActivityAttributes {
    public typealias SleepTimerLiveStatus = ContentState
    public struct ContentState: Codable, Hashable {
        var currentTime: TimeInterval
        var progress: Double
    }
}
