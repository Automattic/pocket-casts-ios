import Foundation
import AutomatticRemoteLogging

class CrashLoggingAdapter: AnalyticsAdapter {
    let crashLogging: CrashLogging?

    static var shared: CrashLoggingAdapter?

    init() {
        self.crashLogging = try? CrashLogging(dataProvider: CrashLoggingDataProvider()).start()
        Self.shared = self
    }

    func track(name: String, properties: [String: Sendable]) async { }
}
