import Foundation
import PocketCastsUtils

enum DataHelper {
    static func convertArrayToInString(_ strArray: [String]) -> String {
        var inString = strArray.joined(separator: ",")
        inString = inString.replacingOccurrences(of: ",", with: "','")
        inString = "'" + inString + "'"

        return inString
    }

    static func run(query: String, values: [Any]?, methodName: String, onQueue: GRDBQueue) {
        onQueue.write { db in
            do {
                try db.executeUpdate(query, values: values)
            } catch {
                FileLog.shared.addMessage("\(methodName) error: \(error)")
            }
        }
    }
}
