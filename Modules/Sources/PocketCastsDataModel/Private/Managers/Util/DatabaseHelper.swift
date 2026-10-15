import Foundation
import PocketCastsUtils

class DatabaseHelper {
    /// Sets up the database schema, running any required migrations.
    /// - Returns: `true` if the database was created from scratch this call (starting
    ///   schema version 0) — i.e. there were no tables to begin with.
    @discardableResult
    class func setup(queue: GRDBQueue) -> Bool {
        var databaseWasCreated = false
        queue.write { db in
            let startingSchemaVersion = db.pragmaUserVersion() ?? 0
            databaseWasCreated = startingSchemaVersion < 1

            var newSchemaVersion = startingSchemaVersion
            try upgradeIfRequired(schemaVersion: &newSchemaVersion, db: db)

            if newSchemaVersion != startingSchemaVersion {
                FileLog.shared.addMessage("Schema update from \(startingSchemaVersion) to \(newSchemaVersion)")
                try db.executeUpdate("PRAGMA user_version = \(newSchemaVersion)", values: nil)
            }
        }
        return databaseWasCreated
    }

    private struct MigrationError: Error, CustomStringConvertible {
        let schemaVersion: Int32
        let underlyingError: Error

        var description: String {
            "Schema update \(schemaVersion) failed: \(underlyingError)"
        }
    }

    private class func migrate(to version: Int32, _ schemaVersion: inout Int32, _ block: () throws -> Void) throws {
        guard schemaVersion < version else { return }
        do {
            try block()
            schemaVersion = version
        } catch {
            throw MigrationError(schemaVersion: version, underlyingError: error)
        }
    }

    private class func upgradeIfRequired(schemaVersion: inout Int32, db: PCDatabase) throws {
        try migrate(to: 1, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE SJPodcast (
                id INTEGER PRIMARY KEY,
                addedDate REAL NOT NULL,
                autoDownloadSetting INTEGER NOT NULL DEFAULT 0,
                episodeKeepSetting INTEGER NOT NULL DEFAULT 0,
                backgroundColor TEXT,
                detailColor TEXT,
                primaryColor TEXT,
                imageURL TEXT,
                secondaryColor TEXT,
                latestEpisodeUuid TEXT,
                latestEpisodeDate REAL,
                lastThumbnailDownloadDate REAL,
                thumbnailStatus INTEGER NOT NULL DEFAULT 1,
                mediaType TEXT,
                playbackSpeed REAL NOT NULL DEFAULT 1,
                podcastCategory TEXT,
                podcastDescription TEXT,
                podcastUrl TEXT,
                author TEXT,
                sortOrder INTEGER NOT NULL DEFAULT 0,
                startFrom INTEGER NOT NULL DEFAULT 0,
                subscribed INTEGER NOT NULL DEFAULT 1,
                thumbnailURL TEXT,
                title TEXT,
                uuid TEXT NOT NULL,
                syncStatus INTEGER NOT NULL DEFAULT 0,
                wasDeleted INTEGER NOT NULL DEFAULT 0
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS podcast_uuid ON SJPodcast (uuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS podcast_sync_status ON SJPodcast (syncStatus);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS podcast_was_deleted ON SJPodcast (wasDeleted);", values: nil)

            try db.executeUpdate("""
                CREATE TABLE SJEpisode (
                id INTEGER PRIMARY KEY,
                addedDate REAL NOT NULL,
                detailedDescription TEXT,
                downloadErrorDetails TEXT,
                downloadTaskId TEXT,
                downloadUrl TEXT,
                duration REAL NOT NULL DEFAULT 0,
                episodeDescription TEXT,
                episodeStatus INTEGER  NOT NULL,
                fileType TEXT,
                keepEpisode INTEGER NOT NULL DEFAULT 0,
                playedUpTo REAL NOT NULL DEFAULT 0,
                playingStatus INTEGER NOT NULL,
                publishedDate REAL,
                showNotes TEXT,
                sizeInBytes INTEGER NOT NULL DEFAULT 0,
                title TEXT,
                uuid TEXT NOT NULL,
                podcastUuid TEXT NOT NULL,
                wasDeleted INTEGER NOT NULL DEFAULT 0,
                podcast_id INTEGER NOT NULL
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_uuid ON SJEpisode (uuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_podcast_uuid ON SJEpisode (podcastUuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_was_deleted ON SJEpisode (wasDeleted);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_pub_date ON SJEpisode (publishedDate);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_podcast_id ON SJEpisode (podcast_id);", values: nil)

            try db.executeUpdate("""
                CREATE TABLE SJFilteredPlaylist (
                id INTEGER PRIMARY KEY,
                autoDownloadEpisodes INTEGER NOT NULL DEFAULT 0,
                customIcon INTEGER NOT NULL DEFAULT 0,
                filterAllPodcasts INTEGER NOT NULL DEFAULT 0,
                filterAudioVideoType INTEGER NOT NULL DEFAULT 0,
                filterDownloaded INTEGER NOT NULL DEFAULT 0,
                filterDownloading INTEGER NOT NULL DEFAULT 0,
                filterFinished INTEGER NOT NULL DEFAULT 0,
                filterNotDownloaded INTEGER NOT NULL DEFAULT 0,
                filterPartiallyPlayed INTEGER NOT NULL DEFAULT 0,
                filterStarred INTEGER NOT NULL DEFAULT 0,
                filterUnplayed INTEGER NOT NULL DEFAULT 0,
                manual INTEGER NOT NULL DEFAULT 0,
                playlistName TEXT NOT NULL,
                podcastUuids TEXT,
                sortPosition INTEGER NOT NULL DEFAULT 0,
                sortType INTEGER NOT NULL DEFAULT 0,
                uuid TEXT NOT NULL,
                syncStatus INTEGER NOT NULL DEFAULT 0,
                wasDeleted INTEGER NOT NULL DEFAULT 0
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS filteredplaylist_uuid ON SJFilteredPlaylist (uuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS filteredplaylist_sync_status ON SJFilteredPlaylist (syncStatus);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS filteredplaylist_was_deleted ON SJFilteredPlaylist (wasDeleted);", values: nil)

            try db.executeUpdate("""
                CREATE TABLE SJPlaylistEpisode (
                id INTEGER PRIMARY KEY,
                episodePosition INTEGER NOT NULL DEFAULT 0,
                episodeUuid TEXT NOT NULL,
                playlist_id INTEGER NOT NULL,
                upcoming INTEGER NOT NULL DEFAULT 0
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_uuid ON SJPlaylistEpisode (episodeUuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_id ON SJPlaylistEpisode (playlist_id);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_upcoming ON SJPlaylistEpisode (upcoming);", values: nil)
        }
        try migrate(to: 2, &schemaVersion) {
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_episodeStatus ON SJEpisode (episodeStatus);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_playingStatus ON SJEpisode (playingStatus);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_keepEpisode ON SJEpisode (keepEpisode);", values: nil)
        }
        try migrate(to: 3, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN playingStatusModified INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN playedUpToModified INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN durationModified INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN wasDeletedModified INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN keepEpisodeModified INTEGER NOT NULL DEFAULT 0;", values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_playing_status_modified ON SJEpisode (playingStatusModified);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_played_opto_modified ON SJEpisode (playedUpToModified);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_duration_modified ON SJEpisode (durationModified);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_was_deleted_modified ON SJEpisode (wasDeletedModified);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_keep_episode_modified ON SJEpisode (keepEpisodeModified);", values: nil)
        }
        try migrate(to: 4, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN pushEnabled INTEGER NOT NULL DEFAULT 1;", values: nil)
        }
        try migrate(to: 5, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeSortOrder INTEGER NOT NULL DEFAULT 1;", values: nil)
        }
        try migrate(to: 6, &schemaVersion) {
            try db.executeUpdate("DELETE FROM SJFilteredPlaylist WHERE manual == 1;", values: nil)
            try db.executeUpdate("DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;", values: nil)
        }
        try migrate(to: 7, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoAddToUpNext INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 8, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN filterHours INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 9, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastDownloadAttemptDate REAL NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS ep_down_date ON SJEpisode (lastDownloadAttemptDate);", values: nil)
        }
        try migrate(to: 10, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN colorVersion INTEGER NOT NULL DEFAULT 1;", values: nil)
        }
        try migrate(to: 11, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN boostVolume INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN trimSilenceAmount INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 12, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN lastColorDownloadDate REAL;", values: nil)
        }
        try migrate(to: 13, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN autoDownloadStatus INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 14, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN playbackErrorDetails TEXT;", values: nil)
        }
        try migrate(to: 15, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN cachedFrameCount INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 16, &schemaVersion) {
            try db.executeUpdate("DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;", values: nil)
            try db.executeUpdate("DROP INDEX IF EXISTS playlist_episode_upcoming;", values: nil)

            try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN timeModified INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN wasDeleted INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN title TEXT;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN podcastUuid TEXT;", values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_time_modified ON SJPlaylistEpisode (timeModified);", values: nil)
        }
        try migrate(to: 17, &schemaVersion) {
            try db.executeUpdate("UPDATE SJEpisode set showNotes = NULL;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionDate REAL;", values: nil)
        }
        try migrate(to: 18, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE UpNextChanges (
                id INTEGER PRIMARY KEY,
                type INTEGER NOT NULL,
                uuid TEXT,
                uuids TEXT,
                utcTime INTEGER NOT NULL
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS up_next_changes_episode ON UpNextChanges (uuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS up_next_changes_time ON UpNextChanges (utcTime);", values: nil)
            try db.executeUpdate("DROP INDEX IF EXISTS playlist_episode_time_modified;", values: nil)
        }

        try migrate(to: 20, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN episodeNumber INTEGER NOT NULL DEFAULT -1;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN seasonNumber INTEGER NOT NULL DEFAULT -1;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN episodeType TEXT;", values: nil)

            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN showType TEXT;", values: nil)
        }
        try migrate(to: 21, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionSyncStatus INTEGER NOT NULL DEFAULT 1;", values: nil)
            try db.executeUpdate("UPDATE SJEpisode SET lastPlaybackInteractionSyncStatus = 0 WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0;", values: nil)
        }
        try migrate(to: 22, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN estimatedNextEpisode REAL;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeFrequency TEXT;", values: nil)
        }
        try migrate(to: 23, &schemaVersion) {
            try db.executeUpdate("DROP INDEX IF EXISTS episode_was_deleted_modified;", values: nil)
            try db.executeUpdate("DROP INDEX IF EXISTS podcast_was_deleted;", values: nil)

            // remove any really old deleted episodes that could be still around
            try db.executeUpdate("DELETE FROM SJEpisode WHERE wasDeleted = 1;", values: nil)

            // set any podcasts that might have been deleted to be unsubscribed instead
            try db.executeUpdate("UPDATE SJPodcast SET subscribed = 0 WHERE wasDeleted = 1;", values: nil)
        }
        try migrate(to: 24, &schemaVersion) {
            // set any podcasts that might have been deleted to be unsubscribed instead
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN lastUpdatedAt TEXT;", values: nil)
        }
        try migrate(to: 25, &schemaVersion) {
            // remove any really old deleted episodes that could be still around
            try db.executeUpdate("DELETE FROM SJEpisode WHERE wasDeleted = 1;", values: nil)

            // add archive columns to episode table
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN archivedModified INTEGER NOT NULL DEFAULT 0;", values: nil)

            // add opt out of auto archive on podcast table
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN excludeFromAutoArchive INTEGER NOT NULL DEFAULT 0;", values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_archived_modified ON SJEpisode (archivedModified);", values: nil)
        }
        try migrate(to: 26, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastArchiveInteractionDate REAL NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 27, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN overrideGlobalEffects INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 28, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN autoDownloadLimit INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 29, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN overrideGlobalArchive INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoArchivePlayedAfter REAL NOT NULL DEFAULT -1;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoArchiveInactiveAfter REAL NOT NULL DEFAULT -1;", values: nil)

            // migrate people who had opt out on, to be overriding global. Since the defaults for all the other settings are off we don't have to worry about setting those
            try db.executeUpdate("UPDATE SJPodcast SET overrideGlobalArchive = 1 WHERE excludeFromAutoArchive = 1;", values: nil)
        }
        try migrate(to: 30, &schemaVersion) {
            // since we're re-using the old database column that was for keep, clear out any legacy values that might be in there
            try db.executeUpdate("UPDATE SJPodcast SET episodeKeepSetting = 0;", values: nil)

            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN excludeFromEpisodeLimit INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 31, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeGrouping INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 32, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE SJUserEpisode (
                id INTEGER PRIMARY KEY,
                addedDate REAL NOT NULL,
                lastDownloadAttemptDate REAL NOT NULL DEFAULT 0,
                downloadErrorDetails TEXT,
                downloadTaskId TEXT,
                downloadUrl TEXT,
                episodeStatus INTEGER  NOT NULL,
                fileType TEXT,
                playedUpTo REAL NOT NULL DEFAULT 0,
                duration REAL NOT NULL DEFAULT 0,
                playingStatus INTEGER NOT NULL,
                autoDownloadStatus INTEGER NOT NULL DEFAULT 0,
                publishedDate REAL,
                sizeInBytes INTEGER NOT NULL DEFAULT 0,
                playingStatusModified INTEGER NOT NULL DEFAULT 0,
                playedUpToModified INTEGER NOT NULL DEFAULT 0,
                title TEXT,
                uuid TEXT NOT NULL,
                playbackErrorDetails TEXT,
                cachedFrameCount INTEGER NOT NULL DEFAULT 0,
                imageUrl TEXT,
                uploadStatus INTEGER NOT NULL,
                uploadTaskId TEXT,
                imageColor INTEGER NOT NULL,
                titleModified INTEGER NOT NULL DEFAULT 0,
                imageColorModified INTEGER NOT NULL DEFAULT 0,
                imageModified INTEGER NOT NULL DEFAULT 0,
                durationModified INTEGER NOT NULL DEFAULT 0,
                hasCustomImage BOOLEAN DEFAULT FALSE
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS user_episode_uuid ON SJUserEpisode (uuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS user_episode_episodeStatus ON SJUserEpisode (episodeStatus);", values: nil)
        }
        try migrate(to: 33, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN skipLast INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 34, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN fullSyncLastSyncAt TEXT;", values: nil)
        }
        try migrate(to: 35, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN showArchived INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 36, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN filterDuration INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN longerThan INTEGER NOT NULL DEFAULT 0;", values: nil)
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN shorterThan INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 37, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN licensing INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 38, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN starredModified INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 39, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN refreshAvailable INTEGER NOT NULL DEFAULT 0;", values: nil)
        }
        try migrate(to: 40, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE IF NOT EXISTS Folder (
                    uuid TEXT NOT NULL,
                    name TEXT NOT NULL,
                    color INTEGER NOT NULL,
                    addedDate INTEGER NOT NULL,
                    sortOrder INTEGER NOT NULL,
                    sortType INTEGER NOT NULL,
                    wasDeleted INTEGER NOT NULL,
                    syncModified INTEGER NOT NULL,
                    PRIMARY KEY(uuid)
                );
            """, values: nil)

            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN folderUuid TEXT;", values: nil)
        }

        try migrate(to: 41, &schemaVersion) {
            try db.executeUpdate("""
            CREATE TABLE IF NOT EXISTS AutoAddCandidates (
                id INTEGER PRIMARY KEY,
                episode_uuid varchar(40) NOT NULL,
                podcast_uuid varchar(40) NOT NULL
            );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS candidate_episode ON AutoAddCandidates (episode_uuid)", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS candidate_podcast ON AutoAddCandidates (podcast_uuid)", values: nil)
        }

        try migrate(to: 42, &schemaVersion) {
            try BookmarkDataManager.createTable(in: db)
        }

        try migrate(to: 43, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN deselectedChapters TEXT;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN settings TEXT NOT NULL DEFAULT '';", values: nil)
        }

        try migrate(to: 44, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN deselectedChaptersModified INTEGER NOT NULL DEFAULT 0;", values: nil)
        }

        try migrate(to: 45, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE EpisodeMetadata (
                    episodeUuid TEXT PRIMARY KEY,
                    metadata TEXT NOT NULL
                );
            """, values: nil)
        }

        try migrate(to: 46, &schemaVersion) {
            try db.executeUpdate("DROP TABLE EpisodeMetadata;", values: nil)
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN metadata TEXT;", values: nil)
        }

        try migrate(to: 47, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN contentType TEXT;", values: nil)
            try db.executeUpdate("ALTER TABLE SJUserEpisode ADD COLUMN contentType TEXT;", values: nil)
        }

        // Those migrations were some heavy DROP COLUMN that we moved outside of DB startup
        if schemaVersion < 48 {
            schemaVersion = 48
        }
        if schemaVersion < 49 {
            schemaVersion = 49
        }

        if schemaVersion < 50 {
            // We are doing try? because depending of the cleanup process was done or not these columns could have been dropped and need to recreated
            // or they still exist because of the changes of version 47.
            try? db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN contentType TEXT;", values: nil)
            try? db.executeUpdate("ALTER TABLE SJUserEpisode ADD COLUMN contentType TEXT;", values: nil)
            schemaVersion = 50
        }

        try migrate(to: 51, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE PlaylistEpisodeHistory (
                id INTEGER KEY,
                episodePosition INTEGER NOT NULL DEFAULT 0,
                episodeUuid TEXT NOT NULL,
                playlist_id INTEGER NOT NULL,
                upcoming INTEGER NOT NULL DEFAULT 0,
                timeModified INTEGER NOT NULL DEFAULT 0,
                wasDeleted INTEGER NOT NULL DEFAULT 0,
                title TEXT,
                podcastUuid TEXT,
                date REAL NOT NULL
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_history_date ON PlaylistEpisodeHistory (date);", values: nil)
        }

        try migrate(to: 52, &schemaVersion) {
            try db.executeUpdate("""
                CREATE TABLE PodcastFoldersHistory (
                podcastUuid TEXT NOT NULL,
                folderUuid TEXT NOT NULL,
                date REAL NOT NULL
                );
            """, values: nil)

            try db.executeUpdate("CREATE INDEX IF NOT EXISTS podcast_folders_history_date ON PlaylistEpisodeHistory (date);", values: nil)
        }

        try migrate(to: 53, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN usedCustomEffectsBefore INTEGER NOT NULL DEFAULT 0;", values: nil)
        }

        try migrate(to: 54, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN podcastHTMLDescription TEXT;", values: nil)
        }

        try migrate(to: 55, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isPrivate INTEGER NOT NULL DEFAULT 0;", values: nil)
        }

        try migrate(to: 56, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN fundingURL TEXT;", values: nil)
        }

        try migrate(to: 57, &schemaVersion) {
            // During the FMDB to GRDB migration, we found some users had corrupted episodes
            // with all columns set to NULL. This cleanup prevents crashes caused by those entries.
            try db.executeUpdate("DELETE FROM SJEpisode WHERE id IS NULL", values: nil)
            try db.executeUpdate("DELETE FROM SJPodcast WHERE id IS NULL", values: nil)
        }

        try migrate(to: 58, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN rawPlaylistType INTEGER NOT NULL DEFAULT 0;", values: nil)
        }

        try migrate(to: 59, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist DROP COLUMN rawPlaylistType;", values: nil)
            try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN playlist_uuid TEXT;", values: nil)
        }

        try migrate(to: 69, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN showArchivedEpisodes BOOLEAN DEFAULT FALSE;", values: nil)
        }

        try migrate(to: 70, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN playlistUpdateDate REAL;", values: nil)
        }

        try migrate(to: 71, &schemaVersion) {
            // Indexes to optimize manual playlist queries by playlist_uuid and ordering by episodePosition
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_uuid ON SJPlaylistEpisode (playlist_uuid);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_uuid_pos ON SJPlaylistEpisode (playlist_uuid, episodePosition);", values: nil)
            try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_uuid_episode ON SJPlaylistEpisode (playlist_uuid, episodeUuid);", values: nil)
        }

        try migrate(to: 72, &schemaVersion) {
            try NetworkDataUsageManager.createTable(in: db)
        }

        try migrate(to: 73, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN hasGeneratedTranscript INTEGER;", values: nil)
        }

        try migrate(to: 74, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isExplicit INTEGER DEFAULT 0;", values: nil)
        }

        try migrate(to: 75, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN hlsUrl TEXT;", values: nil)
        }

        try migrate(to: 76, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN passage TEXT;", values: nil)
            try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN passage_location INTEGER;", values: nil)
            try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN passage_modified_date INTEGER;", values: nil)
            try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN reference_time real;", values: nil)
            try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN reference_time_modified_date INTEGER;", values: nil)
        }

        try migrate(to: 77, &schemaVersion) {
            try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN networkListId TEXT;", values: nil)
        }
    }
}
