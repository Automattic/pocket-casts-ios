import Foundation

public enum LogFilePaths {

    public static var watchUploadLog: String { logDirectory + "/uploadWatchDebug.log" }

    public static var debugUploadLog: String { logDirectory + "/uploadDebug.log" }

    static var mainLogFilePath: String { logDirectory + "/main.log" }

    static var backupLogFilePath: String { logDirectory + "/old.log" }

    // Widget extension log file (shared via App Group)
    public static var widgetLogFilePath: String { sharedLogDirectory + "/widget.log" }

    static var logDirectory: String {
        let directory = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/debug_log")
        return directory
    }

    /// Shared log directory accessible to both the app and widget extension
    static var sharedLogDirectory: String {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.au.com.shiftyjelly.pocketcasts") else {
            // Fallback to regular log directory if App Group is unavailable
            return logDirectory
        }
        let sharedDirectory = containerURL.appendingPathComponent("Logs")

        // Create the directory if it doesn't exist
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: sharedDirectory.path, isDirectory: &isDirectory) {
            try? fileManager.createDirectory(at: sharedDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        return sharedDirectory.path
    }
}
