import Foundation

struct LogEntry {

    // MARK: - Public Properties

    let message: String
    let timestamp: Date

    var formattedForLog: String {
        "\(formatter.string(from: timestamp)) \(message)"
    }

    // MARK: - Private Properties

    private var formatter: DateFormatter {
        DateFormatHelper.sharedHelper.localTimeJsonDateFormatter
    }

    // MARK: - Initializers

    init(_ message: String) {
        self.message = message
        self.timestamp = Date() // Now
    }
}
