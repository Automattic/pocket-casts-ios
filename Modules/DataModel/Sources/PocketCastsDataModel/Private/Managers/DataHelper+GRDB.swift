import GRDB
import PocketCastsUtils

extension DataHelper {
    class func run(query: String, values: [Any]?, methodName: String, dbPool: DatabasePool? = nil) {
        if let dbPool {
            do {
                try dbPool.write { db in
                    try db.execute(sql: query, arguments: StatementArguments(values ?? [])!)
                }
            } catch {
                FileLog.shared.addMessage("\(methodName) error: \(error)")
            }
            return
        }
    }
}
