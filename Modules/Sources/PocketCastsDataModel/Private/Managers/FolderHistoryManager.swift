import PocketCastsUtils
import Foundation

public class FolderHistoryManager {
    /// The number of days to keep the history
    private let periodOfSnapshot: TimeInterval = 14.days

    // MARK: - Queries

    /// Saves a list of podcast UUID and folders UUID so it can be
    /// restored later
    func snapshot(podcastsAndFolders: [String: String], dbQueue: PCDBQueue) {
        dbQueue.write { db in
            do {
                db.beginTransaction()

                let date = Date()
                try podcastsAndFolders.forEach {
                    try db.executeUpdate("INSERT INTO PodcastFoldersHistory VALUES (?, ?, ?)", values: [$0.key, $0.value, date])
                }
                try db.executeUpdate("DELETE FROM PodcastFoldersHistory WHERE date <= ?", values: [Date().addingTimeInterval(-periodOfSnapshot)])

                db.commit()
            } catch {
                FileLog.shared.addMessage("FolderHistoryManager.snapshot error: \(error)")
            }
        }
    }

    /// Return all the available Up Next entries
    func entries(dbQueue: PCDBQueue) -> [PodcastFoldersHistoryEntry] {
        var entries: [PodcastFoldersHistoryEntry] = []
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT COUNT(*) as count, date FROM PodcastFoldersHistory GROUP BY (date) ORDER BY date DESC", values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    if let date = resultSet.date(forColumn: "date") {
                        entries.append(PodcastFoldersHistoryEntry(date: date, changesCount: Int(resultSet.int(forColumn: "count"))))
                    }
                }
            } catch {
                FileLog.shared.addMessage("FolderHistoryManager.entries error: \(error)")
            }
        }

        return entries
    }

    func podcastsAndFolders(entry: Date, dbQueue: PCDBQueue) -> [String: String] {
        var podcastsAndFolders: [String: String] = [:]
        dbQueue.read { db in
            do {
                let resultSet = try db.executeQuery("SELECT podcastUuid, folderUuid FROM PodcastFoldersHistory WHERE date = ?", values: [entry])
                defer { resultSet.close() }

                while resultSet.next() {
                    if let podcastUuid = resultSet.string(forColumn: "podcastUuid"),
                       let folderUuid = resultSet.string(forColumn: "folderUuid") {
                        podcastsAndFolders[podcastUuid] = folderUuid
                    }
                }
            } catch {
                FileLog.shared.addMessage("FolderHistoryManager.podcastsAndFolders error: \(error)")
            }
        }

        return podcastsAndFolders
    }

    public struct PodcastFoldersHistoryEntry: Hashable, Identifiable {
        public var id: Date {
            date
        }

        public let date: Date
        public let changesCount: Int
    }
}

public class FolderHistoryHelper {
    public static let shared = FolderHistoryHelper()

    private var podcastAndFolderUuids: [String: String] = [:]

    public func add(podcastUuid: String, folderUuid: String) {
        podcastAndFolderUuids[podcastUuid] = folderUuid
    }

    public func snapshot() {
        if !podcastAndFolderUuids.isEmpty {
            DataManager.sharedManager.snapshot(podcastsAndFolders: podcastAndFolderUuids)
            podcastAndFolderUuids = [:]
        }
    }
}
