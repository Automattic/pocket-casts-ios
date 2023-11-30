import Foundation

struct LogEntry {

    let message: String
    let timestamp: Date

    init(_ message: String) {
        self.message = message
        self.timestamp = Date() // Now
    }
}
