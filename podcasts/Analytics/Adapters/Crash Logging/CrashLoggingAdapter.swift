import Foundation
import AutomatticRemoteLogging

class CrashLoggingAdapter: AnalyticsAdapter {
    let crashLogging: CrashLogging?

    init() {
        self.crashLogging = try? CrashLogging(dataProvider: CrashLoggingDataProvider()).start()
    }

    func track(name: String, properties: [AnyHashable: Any]?) { }
}
