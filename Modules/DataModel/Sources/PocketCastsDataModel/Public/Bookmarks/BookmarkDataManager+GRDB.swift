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
        grdbQueue.read { db in
            var request = Bookmark
                .filter(Bookmark.Columns.uuid == uuid)

            if !allowDeleted {
                request = request.filter(Bookmark.Columns.deleted == false)
            }

            return try? request
                .order(Bookmark.Columns.created.desc)
                .limit(1)
                .fetchOne(db)
        } ?? nil
    }

    /// Check if a bookmark exists for an episode at a specific time using GRDB QueryInterface
    func existingBookmarkGRDB(forEpisode episodeUuid: String, time: TimeInterval, grdbQueue: GRDBQueue) -> Bookmark? {
        grdbQueue.read { db in
            try? Bookmark
                .filter(Bookmark.Columns.episodeUuid == episodeUuid)
                .filter(Bookmark.Columns.time == time)
                .filter(Bookmark.Columns.deleted == false)
                .order(Bookmark.Columns.created.desc)
                .limit(1)
                .fetchOne(db)
        } ?? nil
    }

    /// Get all bookmarks for an episode using GRDB QueryInterface
    func bookmarksGRDB(forEpisode episodeUuid: String, sorted: SortOption = .newestToOldest, grdbQueue: GRDBQueue) -> [Bookmark] {
        grdbQueue.read { db in
            var request = Bookmark
                .filter(Bookmark.Columns.episodeUuid == episodeUuid)
                .filter(Bookmark.Columns.deleted == false)

            request = applySortOrder(request, sorted: sorted)

            return (try? request.fetchAll(db)) ?? []
        } ?? []
    }

    /// Get all bookmarks for a podcast using GRDB QueryInterface
    func bookmarksGRDB(forPodcast podcastUuid: String, episodeUuid: String? = nil, sorted: SortOption = .newestToOldest, grdbQueue: GRDBQueue) -> [Bookmark] {
        grdbQueue.read { db in
            var request = Bookmark
                .filter(Bookmark.Columns.podcastUuid == podcastUuid)

            if let episodeUuid = episodeUuid {
                request = request.filter(Bookmark.Columns.episodeUuid == episodeUuid)
            }

            // deleted filter comes last to match raw SQL order
            request = request.filter(Bookmark.Columns.deleted == false)

            request = applySortOrder(request, sorted: sorted)

            return (try? request.fetchAll(db)) ?? []
        } ?? []
    }

    /// Get all bookmarks using GRDB QueryInterface
    func allBookmarksGRDB(includeDeleted: Bool = false, sorted: SortOption = .newestToOldest, grdbQueue: GRDBQueue) -> [Bookmark] {
        grdbQueue.read { db in
            var request = Bookmark.all()

            if !includeDeleted {
                request = request.filter(Bookmark.Columns.deleted == false)
            }

            request = applySortOrder(request, sorted: sorted)

            return (try? request.fetchAll(db)) ?? []
        } ?? []
    }

    /// Count bookmarks for an episode using GRDB QueryInterface
    func bookmarkCountGRDB(forEpisode episodeUuid: String, includeDeleted: Bool = false, grdbQueue: GRDBQueue) -> Int {
        grdbQueue.read { db in
            var request = Bookmark.all()

            if !includeDeleted {
                request = request.filter(Bookmark.Columns.deleted == false)
            }

            request = request.filter(Bookmark.Columns.episodeUuid == episodeUuid)

            return (try? request.fetchCount(db)) ?? 0
        } ?? 0
    }

    /// Get bookmarks to sync using GRDB QueryInterface
    func bookmarksToSyncGRDB(grdbQueue: GRDBQueue) -> [Bookmark] {
        grdbQueue.read { db in
            (try? Bookmark
                .filter(Bookmark.Columns.syncStatus == SyncStatus.notSynced.rawValue)
                .order(Bookmark.Columns.created.desc)
                .fetchAll(db)) ?? []
        } ?? []
    }

    // MARK: - Update Methods using GRDB QueryInterface

    /// Mark all bookmarks as synced using GRDB QueryInterface
    @discardableResult
    func markAllBookmarksAsSyncedGRDB(grdbQueue: GRDBQueue) -> Bool {
        grdbQueue.write { db in
            try? Bookmark.updateAll(
                db,
                Bookmark.Columns.syncStatus.set(to: SyncStatus.synced.rawValue)
            )
        } ?? false
    }

    /// Remove bookmarks (mark as deleted) using GRDB QueryInterface
    @discardableResult
    func removeGRDB(bookmarks: [Bookmark], syncStatus: SyncStatus = .notSynced, grdbQueue: GRDBQueue) -> Bool {
        let uuids = bookmarks.map { $0.uuid }

        return grdbQueue.write { db in
            try? Bookmark
                .filter(uuids.contains(Bookmark.Columns.uuid))
                .updateAll(
                    db,
                    Bookmark.Columns.deleted.set(to: true),
                    Bookmark.Columns.deletedModified.set(to: Date()),
                    Bookmark.Columns.syncStatus.set(to: syncStatus.rawValue)
                )
        } ?? false
    }

    /// Permanently delete bookmarks using GRDB QueryInterface
    @discardableResult
    func permanentlyDeleteGRDB(bookmarks: [Bookmark], grdbQueue: GRDBQueue) -> Bool {
        let uuids = bookmarks.map { $0.uuid }

        return grdbQueue.write { db in
            try? Bookmark
                .filter(uuids.contains(Bookmark.Columns.uuid))
                .deleteAll(db)
        } != nil
    }

    // MARK: - Helper Methods

    /// Apply sort order to a Bookmark request
    private func applySortOrder(_ request: QueryInterfaceRequest<Bookmark>, sorted: SortOption) -> QueryInterfaceRequest<Bookmark> {
        switch sorted {
        case .newestToOldest:
            return request.order(Bookmark.Columns.created.desc)
        case .oldestToNewest:
            return request.order(Bookmark.Columns.created.asc)
        case .timestamp, .episode:
            return request.order(Bookmark.Columns.time.asc)
        }
    }
}
