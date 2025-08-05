import Foundation
import AutomatticRemoteLogging

class CrashLoggingAdapter: AnalyticsAdapter {
    let crashLogging: CrashLogging?

    static var sharedManager: CrashLoggingAdapter?

    init() {
        self.crashLogging = try? CrashLogging(dataProvider: CrashLoggingDataProvider()).start()
        Self.sharedManager = self
    }

    func track(name: String, properties: [AnyHashable: Any]?) { }
}
