import Foundation

extension Analytics {
    static func track(_ event: AnalyticsEvent, story: String) {
        Analytics.track(event, properties: ["story": story, "current_year": EndOfYear.currentYear.literalValue])
    }
}
