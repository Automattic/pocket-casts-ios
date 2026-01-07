import Foundation
import os

/// Shared logging for widget extensions
/// Logs are written to the App Group container so they can be accessed by the main app
public final class WidgetLog {
    public static let shared = WidgetLog()

    private let logger = Logger(subsystem: "au.com.shiftyjelly.pocketcasts.widget", category: "Widget")
    private let fileManager = FileManager.default
    private let logFilePath: String
    private let maxLogSize: UInt64 = 500_000 // 500KB max for widget logs

    private init() {
        self.logFilePath = LogFilePaths.widgetLogFilePath

        // Ensure the log file exists
        if !fileManager.fileExists(atPath: logFilePath) {
            fileManager.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
    }

    /// Add a message to the widget log
    /// This will be written to a shared file that the main app can read
    public func addMessage(_ message: String, date: Date = Date()) {
        // Also log to the OS logger for immediate debugging
        logger.log("\(message, privacy: .public)")

        // Format the log entry
        let timestamp = ISO8601DateFormatter().string(from: date)
        let logEntry = "[\(timestamp)] [WIDGET] \(message)\n"

        // Write to the shared log file
        writeToFile(logEntry)
    }

    private func writeToFile(_ message: String) {
        // Rotate log if it's too large
        rotateLogs()

        // Append to the log file
        guard let data = message.data(using: .utf8) else { return }

        if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            // If we can't open the file, try to create it and write
            try? data.write(to: URL(fileURLWithPath: logFilePath), options: .atomic)
        }
    }

    private func rotateLogs() {
        guard let attributes = try? fileManager.attributesOfItem(atPath: logFilePath),
              let fileSize = attributes[.size] as? UInt64,
              fileSize > maxLogSize else {
            return
        }

        // Delete old backup if it exists
        let backupPath = logFilePath.replacingOccurrences(of: ".log", with: ".old.log")
        try? fileManager.removeItem(atPath: backupPath)

        // Move current log to backup
        try? fileManager.moveItem(atPath: logFilePath, toPath: backupPath)

        // Create new log file
        fileManager.createFile(atPath: logFilePath, contents: nil, attributes: nil)

        logger.info("Widget log rotated. Old log saved to backup.")
    }

    /// Read the widget log file contents
    /// This is primarily used by the main app to display widget logs
    public func readLog() -> String {
        let mainLog: String
        do {
            mainLog = try String(contentsOfFile: logFilePath, encoding: .utf8)
        } catch {
            mainLog = "Unable to read widget log: \(error.localizedDescription)"
        }

        // Also include backup log if it exists
        let backupPath = logFilePath.replacingOccurrences(of: ".log", with: ".old.log")
        let backupLog: String
        do {
            backupLog = try String(contentsOfFile: backupPath, encoding: .utf8)
        } catch {
            backupLog = ""
        }

        if backupLog.isEmpty {
            return mainLog
        } else {
            return "\(backupLog)\n--- Current Log ---\n\(mainLog)"
        }
    }

    /// Clear the widget log files
    public func clearLogs() {
        try? fileManager.removeItem(atPath: logFilePath)
        try? fileManager.removeItem(atPath: logFilePath.replacingOccurrences(of: ".log", with: ".old.log"))
        fileManager.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        logger.info("Widget logs cleared")
    }
}
