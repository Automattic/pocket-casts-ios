import FMDB
import SQLite3

public class DatabaseIndexHelper {
    let queue: FMDatabaseQueue

    public init() {
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE
        queue = FMDatabaseQueue(path: DataManager.pathToDb(), flags: flags)!
    }

    public func run() {
        DispatchQueue.global().async { [weak self] in
            self?.queue.inTransaction { db, rollback in
                do {
                    try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_download_task_id ON SJEpisode (downloadTaskId);", values: nil)
                    try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_archived ON SJEpisode (archived);", values: nil)
                    try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_non_null_download_task_id ON SJEpisode(downloadTaskId) WHERE downloadTaskId IS NOT NULL;", values: nil)
                    try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_added_date ON SJEpisode (addedDate);", values: nil)
                } catch {
                    rollback.pointee = true
                }

                self?.queue.close()
            }
        }
    }
}
