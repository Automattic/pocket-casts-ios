import Foundation

public enum LogFilePaths {

    public static var watchUploadLog: String { logDirectory + "/uploadWatchDebug.log" }

    public static var debugUploadLog: String { logDirectory + "/uploadDebug.log" }

    static var mainLogFilePath: String { logDirectory + "/main.log" }

    static var backupLogFilePath: String { logDirectory + "/old.log" }

    static var logDirectory: String {
        let directory = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/debug_log")
        return directory
    }
}
