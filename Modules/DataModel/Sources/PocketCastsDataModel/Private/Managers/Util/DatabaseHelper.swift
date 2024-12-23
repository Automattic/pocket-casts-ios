import FMDB
import GRDB
import Foundation
import PocketCastsUtils

class DatabaseHelper {
    // GRDB setup
    class func setup(dbPool: DatabasePool) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "PRAGMA busy_timeout = 10000")
            }

            var startingSchemaVersion: Int32 = 0
            var newSchemaVersion: Int32 = 0
            try dbPool.read { db in

                let rows = try Row.fetchCursor(db, sql: "PRAGMA user_version")
                if let row = try? rows.next() { startingSchemaVersion = row["user_version"] }

                newSchemaVersion = startingSchemaVersion

                upgradeIfRequired(schemaVersion: &newSchemaVersion, dbPool: dbPool)
            }

            try dbPool.write { db in
                if newSchemaVersion != startingSchemaVersion {
                    try db.execute(sql: "PRAGMA user_version = \(newSchemaVersion)")
                }
            }
        } catch {
            FileLog.shared.addMessage("Failed to setup database, error: \(error)")
        }
    }

    // FMDB setup
    class func setup(db: FMDatabase) {
        do {
            try db.executeQuery("PRAGMA busy_timeout = 10000", values: nil).close()

            var startingSchemaVersion: Int32 = 0

            let rs = try db.executeQuery("PRAGMA user_version", values: nil)
            if rs.next() { startingSchemaVersion = rs.int(forColumnIndex: 0) }
            rs.close()

            var newSchemaVersion = startingSchemaVersion
            upgradeIfRequired(schemaVersion: &newSchemaVersion, db: db)

            if newSchemaVersion != startingSchemaVersion {
                try db.executeUpdate("PRAGMA user_version = \(newSchemaVersion)", values: nil)
            }
        } catch {
            FileLog.shared.addMessage("Failed to setup database \(db.lastErrorCode()): \(db.lastErrorMessage()) actual error: \(error)")
        }
    }

    // GRDB upgradeIfRequired
    private class func upgradeIfRequired(schemaVersion: inout Int32, dbPool: DatabasePool) {
        do {
            try dbPool.writeInTransaction { db in

                if schemaVersion < 1 {
                    try db.execute(sql: """
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
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS podcast_uuid ON SJPodcast (uuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS podcast_sync_status ON SJPodcast (syncStatus);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS podcast_was_deleted ON SJPodcast (wasDeleted);")

                    try db.execute(sql: """
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
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_uuid ON SJEpisode (uuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_podcast_uuid ON SJEpisode (podcastUuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_was_deleted ON SJEpisode (wasDeleted);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_pub_date ON SJEpisode (publishedDate);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_podcast_id ON SJEpisode (podcast_id);")

                    try db.execute(sql: """
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
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS filteredplaylist_uuid ON SJFilteredPlaylist (uuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS filteredplaylist_sync_status ON SJFilteredPlaylist (syncStatus);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS filteredplaylist_was_deleted ON SJFilteredPlaylist (wasDeleted);")

                    try db.execute(sql: """
                        CREATE TABLE SJPlaylistEpisode (
                        id INTEGER PRIMARY KEY,
                        episodePosition INTEGER NOT NULL DEFAULT 0,
                        episodeUuid TEXT NOT NULL,
                        playlist_id INTEGER NOT NULL,
                        upcoming INTEGER NOT NULL DEFAULT 0
                        );
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS playlist_episode_uuid ON SJPlaylistEpisode (episodeUuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS playlist_episode_playlist_id ON SJPlaylistEpisode (playlist_id);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS playlist_episode_upcoming ON SJPlaylistEpisode (upcoming);")

                    schemaVersion = 1
                }

                if schemaVersion < 2 {
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_episodeStatus ON SJEpisode (episodeStatus);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_playingStatus ON SJEpisode (playingStatus);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_keepEpisode ON SJEpisode (keepEpisode);")

                    schemaVersion = 2
                }

                if schemaVersion < 3 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN playingStatusModified INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN playedUpToModified INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN durationModified INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN wasDeletedModified INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN keepEpisodeModified INTEGER NOT NULL DEFAULT 0;")

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_playing_status_modified ON SJEpisode (playingStatusModified);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_played_opto_modified ON SJEpisode (playedUpToModified);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_duration_modified ON SJEpisode (durationModified);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_was_deleted_modified ON SJEpisode (wasDeletedModified);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_keep_episode_modified ON SJEpisode (keepEpisodeModified);")

                    schemaVersion = 3
                }

                if schemaVersion < 4 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN pushEnabled INTEGER NOT NULL DEFAULT 1;")
                    schemaVersion = 4
                }

                if schemaVersion < 5 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN episodeSortOrder INTEGER NOT NULL DEFAULT 1;")
                    schemaVersion = 5
                }

                if schemaVersion < 6 {
                    try db.execute(sql: "DELETE FROM SJFilteredPlaylist WHERE manual == 1;")
                    try db.execute(sql: "DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;")
                    schemaVersion = 6
                }

                if schemaVersion < 7 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN autoAddToUpNext INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 7
                }

                if schemaVersion < 8 {
                    try db.execute(sql: "ALTER TABLE SJFilteredPlaylist ADD COLUMN filterHours INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 8
                }

                if schemaVersion < 9 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN lastDownloadAttemptDate REAL NOT NULL DEFAULT 0;")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS ep_down_date ON SJEpisode (lastDownloadAttemptDate);")
                    schemaVersion = 9
                }

                if schemaVersion < 10 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN colorVersion INTEGER NOT NULL DEFAULT 1;")
                    schemaVersion = 10
                }

                if schemaVersion < 11 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN boostVolume INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN trimSilenceAmount INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 11
                }

                if schemaVersion < 12 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN lastColorDownloadDate REAL;")
                    schemaVersion = 12
                }

                if schemaVersion < 13 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN autoDownloadStatus INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 13
                }

                if schemaVersion < 14 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN playbackErrorDetails TEXT;")
                    schemaVersion = 14
                }

                if schemaVersion < 15 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN cachedFrameCount INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 15
                }

                if schemaVersion < 16 {
                    try db.execute(sql: "DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;")
                    try db.execute(sql: "DROP INDEX IF EXISTS playlist_episode_upcoming;")

                    try db.execute(sql: "ALTER TABLE SJPlaylistEpisode ADD COLUMN timeModified INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJPlaylistEpisode ADD COLUMN wasDeleted INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJPlaylistEpisode ADD COLUMN title TEXT;")
                    try db.execute(sql: "ALTER TABLE SJPlaylistEpisode ADD COLUMN podcastUuid TEXT;")

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS playlist_episode_time_modified ON SJPlaylistEpisode (timeModified);")
                    schemaVersion = 16
                }

                if schemaVersion < 17 {
                    try db.execute(sql: "UPDATE SJEpisode set showNotes = NULL;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionDate REAL;")
                    schemaVersion = 17
                }

                if schemaVersion < 18 {
                    try db.execute(sql: """
                        CREATE TABLE UpNextChanges (
                        id INTEGER PRIMARY KEY,
                        type INTEGER NOT NULL,
                        uuid TEXT,
                        uuids TEXT,
                        utcTime INTEGER NOT NULL
                        );
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS up_next_changes_episode ON UpNextChanges (uuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS up_next_changes_time ON UpNextChanges (utcTime);")
                    try db.execute(sql: "DROP INDEX IF EXISTS playlist_episode_time_modified;")

                    schemaVersion = 18
                }

                if schemaVersion < 20 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN episodeNumber INTEGER NOT NULL DEFAULT -1;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN seasonNumber INTEGER NOT NULL DEFAULT -1;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN episodeType TEXT;")

                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN showType TEXT;")

                    schemaVersion = 20
                }

                if schemaVersion < 21 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionSyncStatus INTEGER NOT NULL DEFAULT 1;")
                    try db.execute(sql: "UPDATE SJEpisode SET lastPlaybackInteractionSyncStatus = 0 WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0;")

                    schemaVersion = 21
                }

                if schemaVersion < 22 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN estimatedNextEpisode REAL;")
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN episodeFrequency TEXT;")

                    schemaVersion = 22
                }

                if schemaVersion < 23 {
                    try db.execute(sql: "DROP INDEX IF EXISTS episode_was_deleted_modified;")
                    try db.execute(sql: "DROP INDEX IF EXISTS podcast_was_deleted;")

                    // remove any really old deleted episodes that could be still around
                    try db.execute(sql: "DELETE FROM SJEpisode WHERE wasDeleted = 1;")

                    // set any podcasts that might have been deleted to be unsubscribed instead
                    try db.execute(sql: "UPDATE SJPodcast SET subscribed = 0 WHERE wasDeleted = 1;")

                    schemaVersion = 23
                }

                if schemaVersion < 24 {
                    // set any podcasts that might have been deleted to be unsubscribed instead
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN lastUpdatedAt TEXT;")
                    schemaVersion = 24
                }

                if schemaVersion < 25 {
                    // remove any really old deleted episodes that could be still around
                    try db.execute(sql: "DELETE FROM SJEpisode WHERE wasDeleted = 1;")

                    // add archive columns to episode table
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN archivedModified INTEGER NOT NULL DEFAULT 0;")

                    // add opt out of auto archive on podcast table
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN excludeFromAutoArchive INTEGER NOT NULL DEFAULT 0;")

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_archived_modified ON SJEpisode (archivedModified);")

                    schemaVersion = 25
                }

                if schemaVersion < 26 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN lastArchiveInteractionDate REAL NOT NULL DEFAULT 0;")
                    schemaVersion = 26
                }

                if schemaVersion < 27 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN overrideGlobalEffects INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 27
                }

                if schemaVersion < 28 {
                    try db.execute(sql: "ALTER TABLE SJFilteredPlaylist ADD COLUMN autoDownloadLimit INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 28
                }

                if schemaVersion < 29 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN overrideGlobalArchive INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN autoArchivePlayedAfter REAL NOT NULL DEFAULT -1;")
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN autoArchiveInactiveAfter REAL NOT NULL DEFAULT -1;")

                    // migrate people who had opt out on, to be overriding global. Since the defaults for all the other settings are off we don't have to worry about setting those
                    try db.execute(sql: "UPDATE SJPodcast SET overrideGlobalArchive = 1 WHERE excludeFromAutoArchive = 1;")
                    schemaVersion = 29
                }

                if schemaVersion < 30 {
                    // since we're re-using the old database column that was for keep, clear out any legacy values that might be in there
                    try db.execute(sql: "UPDATE SJPodcast SET episodeKeepSetting = 0;")

                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN excludeFromEpisodeLimit INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 30
                }

                if schemaVersion < 31 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN episodeGrouping INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 31
                }

                if schemaVersion < 32 {
                    try db.execute(sql: """
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
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS user_episode_uuid ON SJUserEpisode (uuid);")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS user_episode_episodeStatus ON SJUserEpisode (episodeStatus);")
                    schemaVersion = 32
                }

                if schemaVersion < 33 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN skipLast INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 33
                }

                if schemaVersion < 34 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN fullSyncLastSyncAt TEXT;")
                    schemaVersion = 34
                }

                if schemaVersion < 35 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN showArchived INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 35
                }

                if schemaVersion < 36 {
                    try db.execute(sql: "ALTER TABLE SJFilteredPlaylist ADD COLUMN filterDuration INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJFilteredPlaylist ADD COLUMN longerThan INTEGER NOT NULL DEFAULT 0;")
                    try db.execute(sql: "ALTER TABLE SJFilteredPlaylist ADD COLUMN shorterThan INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 36
                }

                if schemaVersion < 37 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN licensing INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 37
                }

                if schemaVersion < 38 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN starredModified INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 38
                }

                if schemaVersion < 39 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN refreshAvailable INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 39
                }

                if schemaVersion < 40 {
                    try db.execute(sql: """
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
                    """)

                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN folderUuid TEXT;")

                    schemaVersion = 40
                }

                if schemaVersion < 41 {
                    try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS AutoAddCandidates (
                        id INTEGER PRIMARY KEY,
                        episode_uuid varchar(40) NOT NULL,
                        podcast_uuid varchar(40) NOT NULL
                    );
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS candidate_episode ON AutoAddCandidates (episode_uuid)")
                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS candidate_podcast ON AutoAddCandidates (podcast_uuid)")

                    schemaVersion = 41
                }

                if schemaVersion < 42 {
                    try BookmarkDataManager.createTable(in: db)

                    schemaVersion = 42
                }

                if schemaVersion < 43 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN deselectedChapters TEXT;")
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN settings TEXT NOT NULL DEFAULT '';")
                    schemaVersion = 43
                }

                if schemaVersion < 44 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN deselectedChaptersModified INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 44
                }

                if schemaVersion < 45 {
                    try db.execute(sql: """
                        CREATE TABLE EpisodeMetadata (
                            episodeUuid TEXT PRIMARY KEY,
                            metadata TEXT NOT NULL
                        );
                    """)
                    schemaVersion = 45
                }

                if schemaVersion < 46 {
                    try db.execute(sql: "DROP TABLE EpisodeMetadata;")
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN metadata TEXT;")
                    schemaVersion = 46
                }

                if schemaVersion < 47 {
                    try db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN contentType TEXT;")
                    try db.execute(sql: "ALTER TABLE SJUserEpisode ADD COLUMN contentType TEXT;")
                    schemaVersion = 47
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
                    try? db.execute(sql: "ALTER TABLE SJEpisode ADD COLUMN contentType TEXT;")
                    try? db.execute(sql: "ALTER TABLE SJUserEpisode ADD COLUMN contentType TEXT;")
                    schemaVersion = 50
                }

                if schemaVersion < 51 {
                    try db.execute(sql: """
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
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS episode_history_date ON PlaylistEpisodeHistory (date);")

                    schemaVersion = 51
                }

                if schemaVersion < 52 {
                    try db.execute(sql: """
                        CREATE TABLE PodcastFoldersHistory (
                        podcastUuid TEXT NOT NULL,
                        folderUuid TEXT NOT NULL,
                        date REAL NOT NULL
                        );
                    """)

                    try db.execute(sql: "CREATE INDEX IF NOT EXISTS podcast_folders_history_date ON PlaylistEpisodeHistory (date);")

                    schemaVersion = 52
                }

                if schemaVersion < 53 {
                    try db.execute(sql: "ALTER TABLE SJPodcast ADD COLUMN usedCustomEffectsBefore INTEGER NOT NULL DEFAULT 0;")
                    schemaVersion = 53
                }


                return .commit
            }
        } catch {
            FileLog.shared.addMessage("Schema update \(schemaVersion+1) failed: \(error.localizedDescription)")
        }
    }

    // FMDB upgradeIfRequired
    private class func upgradeIfRequired(schemaVersion: inout Int32, db: FMDatabase) {
        db.beginTransaction()

        let failedAt = { (statement: Int) in
            let lastErrorCode = db.lastErrorCode()
            let lastErrorMessage = db.lastErrorMessage()
            db.rollback()
            FileLog.shared.addMessage("Schema update \(statement) failed, code \(lastErrorCode): \(lastErrorMessage)")
        }

        if schemaVersion < 1 {
            do {
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

                schemaVersion = 1
            } catch {
                failedAt(1)
                return
            }
        }
        if schemaVersion < 2 {
            do {
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_episodeStatus ON SJEpisode (episodeStatus);", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_playingStatus ON SJEpisode (playingStatus);", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_keepEpisode ON SJEpisode (keepEpisode);", values: nil)

                schemaVersion = 2
            } catch {
                failedAt(2)
                return
            }
        }
        if schemaVersion < 3 {
            do {
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

                schemaVersion = 3
            } catch {
                failedAt(3)
                return
            }
        }
        if schemaVersion < 4 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN pushEnabled INTEGER NOT NULL DEFAULT 1;", values: nil)
                schemaVersion = 4
            } catch {
                failedAt(4)
                return
            }
        }
        if schemaVersion < 5 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeSortOrder INTEGER NOT NULL DEFAULT 1;", values: nil)
                schemaVersion = 5
            } catch {
                failedAt(5)
                return
            }
        }
        if schemaVersion < 6 {
            do {
                try db.executeUpdate("DELETE FROM SJFilteredPlaylist WHERE manual == 1;", values: nil)
                try db.executeUpdate("DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;", values: nil)
                schemaVersion = 6
            } catch {
                failedAt(6)
                return
            }
        }
        if schemaVersion < 7 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoAddToUpNext INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 7
            } catch {
                failedAt(7)
                return
            }
        }
        if schemaVersion < 8 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN filterHours INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 8
            } catch {
                failedAt(8)
                return
            }
        }
        if schemaVersion < 9 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastDownloadAttemptDate REAL NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS ep_down_date ON SJEpisode (lastDownloadAttemptDate);", values: nil)
                schemaVersion = 9
            } catch {
                failedAt(9)
                return
            }
        }
        if schemaVersion < 10 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN colorVersion INTEGER NOT NULL DEFAULT 1;", values: nil)
                schemaVersion = 10
            } catch {
                failedAt(10)
                return
            }
        }
        if schemaVersion < 11 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN boostVolume INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN trimSilenceAmount INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 11
            } catch {
                failedAt(11)
                return
            }
        }
        if schemaVersion < 12 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN lastColorDownloadDate REAL;", values: nil)
                schemaVersion = 12
            } catch {
                failedAt(12)
                return
            }
        }
        if schemaVersion < 13 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN autoDownloadStatus INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 13
            } catch {
                failedAt(13)
                return
            }
        }
        if schemaVersion < 14 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN playbackErrorDetails TEXT;", values: nil)
                schemaVersion = 14
            } catch {
                failedAt(14)
                return
            }
        }
        if schemaVersion < 15 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN cachedFrameCount INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 15
            } catch {
                failedAt(15)
                return
            }
        }
        if schemaVersion < 16 {
            do {
                try db.executeUpdate("DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;", values: nil)
                try db.executeUpdate("DROP INDEX IF EXISTS playlist_episode_upcoming;", values: nil)

                try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN timeModified INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN wasDeleted INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN title TEXT;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN podcastUuid TEXT;", values: nil)

                try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_time_modified ON SJPlaylistEpisode (timeModified);", values: nil)
                schemaVersion = 16
            } catch {
                failedAt(16)
                return
            }
        }
        if schemaVersion < 17 {
            do {
                try db.executeUpdate("UPDATE SJEpisode set showNotes = NULL;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionDate REAL;", values: nil)
                schemaVersion = 17
            } catch {
                failedAt(17)
                return
            }
        }
        if schemaVersion < 18 {
            do {
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

                schemaVersion = 18
            } catch {
                failedAt(18)
                return
            }
        }

        if schemaVersion < 20 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN episodeNumber INTEGER NOT NULL DEFAULT -1;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN seasonNumber INTEGER NOT NULL DEFAULT -1;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN episodeType TEXT;", values: nil)

                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN showType TEXT;", values: nil)

                schemaVersion = 20
            } catch {
                failedAt(20)
                return
            }
        }
        if schemaVersion < 21 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionSyncStatus INTEGER NOT NULL DEFAULT 1;", values: nil)
                try db.executeUpdate("UPDATE SJEpisode SET lastPlaybackInteractionSyncStatus = 0 WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0;", values: nil)

                schemaVersion = 21
            } catch {
                failedAt(21)
                return
            }
        }
        if schemaVersion < 22 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN estimatedNextEpisode REAL;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeFrequency TEXT;", values: nil)

                schemaVersion = 22
            } catch {
                failedAt(22)
                return
            }
        }
        if schemaVersion < 23 {
            do {
                try db.executeUpdate("DROP INDEX IF EXISTS episode_was_deleted_modified;", values: nil)
                try db.executeUpdate("DROP INDEX IF EXISTS podcast_was_deleted;", values: nil)

                // remove any really old deleted episodes that could be still around
                try db.executeUpdate("DELETE FROM SJEpisode WHERE wasDeleted = 1;", values: nil)

                // set any podcasts that might have been deleted to be unsubscribed instead
                try db.executeUpdate("UPDATE SJPodcast SET subscribed = 0 WHERE wasDeleted = 1;", values: nil)

                schemaVersion = 23
            } catch {
                failedAt(23)
                return
            }
        }
        if schemaVersion < 24 {
            do {
                // set any podcasts that might have been deleted to be unsubscribed instead
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN lastUpdatedAt TEXT;", values: nil)
                schemaVersion = 24
            } catch {
                failedAt(24)
                return
            }
        }
        if schemaVersion < 25 {
            do {
                // remove any really old deleted episodes that could be still around
                try db.executeUpdate("DELETE FROM SJEpisode WHERE wasDeleted = 1;", values: nil)

                // add archive columns to episode table
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN archivedModified INTEGER NOT NULL DEFAULT 0;", values: nil)

                // add opt out of auto archive on podcast table
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN excludeFromAutoArchive INTEGER NOT NULL DEFAULT 0;", values: nil)

                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_archived_modified ON SJEpisode (archivedModified);", values: nil)

                schemaVersion = 25
            } catch {
                failedAt(25)
                return
            }
        }
        if schemaVersion < 26 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastArchiveInteractionDate REAL NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 26
            } catch {
                failedAt(26)
                return
            }
        }
        if schemaVersion < 27 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN overrideGlobalEffects INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 27
            } catch {
                failedAt(27)
                return
            }
        }
        if schemaVersion < 28 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN autoDownloadLimit INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 28
            } catch {
                failedAt(28)
                return
            }
        }
        if schemaVersion < 29 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN overrideGlobalArchive INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoArchivePlayedAfter REAL NOT NULL DEFAULT -1;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoArchiveInactiveAfter REAL NOT NULL DEFAULT -1;", values: nil)

                // migrate people who had opt out on, to be overriding global. Since the defaults for all the other settings are off we don't have to worry about setting those
                try db.executeUpdate("UPDATE SJPodcast SET overrideGlobalArchive = 1 WHERE excludeFromAutoArchive = 1;", values: nil)
                schemaVersion = 29
            } catch {
                failedAt(29)
                return
            }
        }
        if schemaVersion < 30 {
            do {
                // since we're re-using the old database column that was for keep, clear out any legacy values that might be in there
                try db.executeUpdate("UPDATE SJPodcast SET episodeKeepSetting = 0;", values: nil)

                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN excludeFromEpisodeLimit INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 30
            } catch {
                failedAt(30)
                return
            }
        }
        if schemaVersion < 31 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeGrouping INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 31
            } catch {
                failedAt(31)
                return
            }
        }
        if schemaVersion < 32 {
            do {
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
                schemaVersion = 32
            } catch {
                failedAt(32)
                return
            }
        }
        if schemaVersion < 33 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN skipLast INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 33
            } catch {
                failedAt(33)
                return
            }
        }
        if schemaVersion < 34 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN fullSyncLastSyncAt TEXT;", values: nil)
                schemaVersion = 34
            } catch {
                failedAt(34)
                return
            }
        }
        if schemaVersion < 35 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN showArchived INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 35
            } catch {
                failedAt(35)
                return
            }
        }
        if schemaVersion < 36 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN filterDuration INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN longerThan INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN shorterThan INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 36
            } catch {
                failedAt(36)
                return
            }
        }
        if schemaVersion < 37 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN licensing INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 37
            } catch {
                failedAt(37)
                return
            }
        }
        if schemaVersion < 38 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN starredModified INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 38
            } catch {
                failedAt(38)
                return
            }
        }
        if schemaVersion < 39 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN refreshAvailable INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 39
            } catch {
                failedAt(39)
                return
            }
        }
        if schemaVersion < 40 {
            do {
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

                schemaVersion = 40
            } catch {
                failedAt(40)
                return
            }
        }

        if schemaVersion < 41 {
            do {
                try db.executeUpdate("""
                CREATE TABLE IF NOT EXISTS AutoAddCandidates (
                    id INTEGER PRIMARY KEY,
                    episode_uuid varchar(40) NOT NULL,
                    podcast_uuid varchar(40) NOT NULL
                );
                """, values: nil)

                try db.executeUpdate("CREATE INDEX IF NOT EXISTS candidate_episode ON AutoAddCandidates (episode_uuid)", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS candidate_podcast ON AutoAddCandidates (podcast_uuid)", values: nil)

                schemaVersion = 41
            } catch {
                failedAt(41)
            }
        }

        if schemaVersion < 42 {
            do {
                try BookmarkDataManager.createTable(in: db)

                schemaVersion = 42
            } catch {
                failedAt(42)
                return
            }
        }

        if schemaVersion < 43 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN deselectedChapters TEXT;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN settings TEXT NOT NULL DEFAULT '';", values: nil)
                schemaVersion = 43
            } catch {
                failedAt(43)
                return
            }
        }

        if schemaVersion < 44 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN deselectedChaptersModified INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 44
            } catch {
                failedAt(44)
                return
            }
        }

        if schemaVersion < 45 {
            do {
                try db.executeUpdate("""
                    CREATE TABLE EpisodeMetadata (
                        episodeUuid TEXT PRIMARY KEY,
                        metadata TEXT NOT NULL
                    );
                """, values: nil)
                schemaVersion = 45
            } catch {
                failedAt(45)
                return
            }
        }

        if schemaVersion < 46 {
            do {
                try db.executeUpdate("DROP TABLE EpisodeMetadata;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN metadata TEXT;", values: nil)
                schemaVersion = 46
            } catch {
                failedAt(46)
                return
            }
        }

        if schemaVersion < 47 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN contentType TEXT;", values: nil)
                try db.executeUpdate("ALTER TABLE SJUserEpisode ADD COLUMN contentType TEXT;", values: nil)
                schemaVersion = 47
            } catch {
                failedAt(47)
                return
            }
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

        if schemaVersion < 51 {
            do {
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

                schemaVersion = 51
            } catch {
                failedAt(51)
                return
            }
        }

        if schemaVersion < 52 {
            do {
                try db.executeUpdate("""
                    CREATE TABLE PodcastFoldersHistory (
                    podcastUuid TEXT NOT NULL,
                    folderUuid TEXT NOT NULL,
                    date REAL NOT NULL
                    );
                """, values: nil)

                try db.executeUpdate("CREATE INDEX IF NOT EXISTS podcast_folders_history_date ON PlaylistEpisodeHistory (date);", values: nil)

                schemaVersion = 52
            } catch {
                failedAt(52)
                return
            }
        }

        if schemaVersion < 53 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN usedCustomEffectsBefore INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 53
            } catch {
                failedAt(53)
                return
            }
        }

        if schemaVersion < 54 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN podcastHTMLDescription TEXT;", values: nil)
                schemaVersion = 54
            } catch {
                failedAt(54)
                return
            }
        }

        db.commit()
    }
}
