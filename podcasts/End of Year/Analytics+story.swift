import Foundation

extension Analytics {
    static func track(_ event: AnalyticsEvent, story: String) {
        Analytics.track(event, properties: ["story": story, "year": EndOfYear.currentYear.literalValue])
    }
}
