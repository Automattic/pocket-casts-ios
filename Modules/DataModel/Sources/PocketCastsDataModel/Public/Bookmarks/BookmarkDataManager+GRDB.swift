import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for BookmarkDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main BookmarkDataManager methods when the grdbQueryInterface feature flag is enabled.
extension BookmarkDataManager {

    // MARK: - Query Methods using GRDB QueryInterface

    /// Find a bookmark by UUID using GRDB QueryInterface
    func bookmarkGRDB(for uuid: String, allowDeleted: Bool = false, grdbQueue: GRDBQueue) -> Bookmark? {
        let record: BookmarkRecord? = grdbQueue.read { db in
            var request = BookmarkRecord
                .filter(BookmarkRecord.Columns.uuid == uuid)

            if !allowDeleted {
                request = request.filter(BookmarkRecord.Columns.deleted == false)
            }

            return try? request.fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return bookmarkFromRecord(record)
    }

    /// Check if a bookmark exists for an episode at a specific time using GRDB QueryInterface
    func existingBookmarkGRDB(forEpisode episodeUuid: String, time: TimeInterval, grdbQueue: GRDBQueue) -> Bookmark? {
        let record: BookmarkRecord? = grdbQueue.read { db in
            try? BookmarkRecord
                .filter(BookmarkRecord.Columns.episode_uuid == episodeUuid)
                .filter(BookmarkRecord.Columns.time == time)
                .filter(BookmarkRecord.Columns.deleted == false)
                .limit(1)
                .fetchOne(db)
        } ?? nil

        guard let record = record else { return nil }
        return bookmarkFromRecord(record)
    }

    /// Get all bookmarks for an episode using GRDB QueryInterface
    func bookmarksGRDB(forEpisode episodeUuid: String, sorted: SortOption = .newestToOldest, grdbQueue: GRDBQueue) -> [Bookmark] {
        let records: [BookmarkRecord] = grdbQueue.read { db in
            var request = BookmarkRecord
                .filter(BookmarkRecord.Columns.episode_uuid == episodeUuid)
                .filter(BookmarkRecord.Columns.deleted == false)

            request = applySortOrder(request, sorted: sorted)

            return (try? request.fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { bookmarkFromRecord($0) }
    }

    /// Get all bookmarks for a podcast using GRDB QueryInterface
    func bookmarksGRDB(forPodcast podcastUuid: String, episodeUuid: String? = nil, sorted: SortOption = .newestToOldest, grdbQueue: GRDBQueue) -> [Bookmark] {
        let records: [BookmarkRecord] = grdbQueue.read { db in
            var request = BookmarkRecord
                .filter(BookmarkRecord.Columns.podcast_uuid == podcastUuid)
                .filter(BookmarkRecord.Columns.deleted == false)

            if let episodeUuid = episodeUuid {
                request = request.filter(BookmarkRecord.Columns.episode_uuid == episodeUuid)
            }

            request = applySortOrder(request, sorted: sorted)

            return (try? request.fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { bookmarkFromRecord($0) }
    }

    /// Get all bookmarks using GRDB QueryInterface
    func allBookmarksGRDB(includeDeleted: Bool = false, sorted: SortOption = .newestToOldest, grdbQueue: GRDBQueue) -> [Bookmark] {
        let records: [BookmarkRecord] = grdbQueue.read { db in
            var request = BookmarkRecord.all()

            if !includeDeleted {
                request = request.filter(BookmarkRecord.Columns.deleted == false)
            }

            request = applySortOrder(request, sorted: sorted)

            return (try? request.fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { bookmarkFromRecord($0) }
    }

    /// Count bookmarks for an episode using GRDB QueryInterface
    func bookmarkCountGRDB(forEpisode episodeUuid: String, includeDeleted: Bool = false, grdbQueue: GRDBQueue) -> Int {
        return grdbQueue.read { db in
            var request = BookmarkRecord
                .filter(BookmarkRecord.Columns.episode_uuid == episodeUuid)

            if !includeDeleted {
                request = request.filter(BookmarkRecord.Columns.deleted == false)
            }

            return (try? request.fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Get bookmarks to sync using GRDB QueryInterface
    func bookmarksToSyncGRDB(grdbQueue: GRDBQueue) -> [Bookmark] {
        let records: [BookmarkRecord] = grdbQueue.read { db in
            (try? BookmarkRecord
                .filter(BookmarkRecord.Columns.sync_status == SyncStatus.notSynced.rawValue)
                .fetchAll(db)) ?? []
        } ?? []

        return records.compactMap { bookmarkFromRecord($0) }
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Mark all bookmarks as synced using GRDB QueryInterface
    @discardableResult
    func markAllBookmarksAsSyncedGRDB(grdbQueue: GRDBQueue) -> Bool {
        return grdbQueue.write { db in
            try? BookmarkRecord.updateAll(
                db,
                BookmarkRecord.Columns.sync_status.set(to: SyncStatus.synced.rawValue)
            )
        } ?? false
    }

    /// Remove bookmarks (mark as deleted) using GRDB QueryInterface
    @discardableResult
    func removeGRDB(bookmarks: [Bookmark], syncStatus: SyncStatus = .notSynced, grdbQueue: GRDBQueue) -> Bool {
        let uuids = bookmarks.map { $0.uuid }

        return grdbQueue.write { db in
            try? BookmarkRecord
                .filter(uuids.contains(BookmarkRecord.Columns.uuid))
                .updateAll(
                    db,
                    BookmarkRecord.Columns.deleted.set(to: true),
                    BookmarkRecord.Columns.deleted_modified_date.set(to: Date().timeIntervalSince1970),
                    BookmarkRecord.Columns.sync_status.set(to: syncStatus.rawValue)
                )
        } ?? false
    }

    /// Permanently delete bookmarks using GRDB QueryInterface
    @discardableResult
    func permanentlyDeleteGRDB(bookmarks: [Bookmark], grdbQueue: GRDBQueue) -> Bool {
        let uuids = bookmarks.map { $0.uuid }

        return grdbQueue.write { db in
            try? BookmarkRecord
                .filter(uuids.contains(BookmarkRecord.Columns.uuid))
                .deleteAll(db)
        } != nil
    }

    // MARK: - Helper Methods

    /// Apply sort order to a BookmarkRecord request
    private func applySortOrder(_ request: QueryInterfaceRequest<BookmarkRecord>, sorted: SortOption) -> QueryInterfaceRequest<BookmarkRecord> {
        switch sorted {
        case .newestToOldest:
            return request.order(BookmarkRecord.Columns.date_added.desc)
        case .oldestToNewest:
            return request.order(BookmarkRecord.Columns.date_added.asc)
        case .timestamp, .episode:
            return request.order(BookmarkRecord.Columns.time.asc)
        }
    }

    /// Convert a BookmarkRecord to a Bookmark model object
    private func bookmarkFromRecord(_ record: BookmarkRecord) -> Bookmark? {
        let created = Date(timeIntervalSince1970: record.date_added)
        let titleModified = record.title_modified_date.map { Date(timeIntervalSince1970: $0) }
        let deletedModified = record.deleted_modified_date.map { Date(timeIntervalSince1970: $0) }

        return Bookmark(
            uuid: record.uuid,
            title: record.title,
            time: record.time,
            created: created,
            episodeUuid: record.episode_uuid,
            podcastUuid: record.podcast_uuid,
            titleModified: titleModified,
            deletedModified: deletedModified,
            deleted: record.deleted
        )
    }
}
