import FMDB
import Foundation
import PocketCastsUtils

class DataHelper {
    class func convertArrayToInString(_ strArray: [String]) -> String {
        var inString = strArray.joined(separator: ",")
        inString = inString.replacingOccurrences(of: ",", with: "\",\"")
        inString = "\"" + inString + "\""

        return inString
    }




    

    class func run(query: String, values: [Any]?, methodName: String, onQueue: FMDatabaseQueue) {
        onQueue.inTransaction { db, _ in
            do {
                try db.executeUpdate(query, values: values)
            } catch {
                FileLog.shared.addMessage("\(methodName) error: \(error)")
            }
        }
    }
}
