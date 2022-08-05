import Foundation

enum AnalyticsEvent: String {
    case applicationOpened

    var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
