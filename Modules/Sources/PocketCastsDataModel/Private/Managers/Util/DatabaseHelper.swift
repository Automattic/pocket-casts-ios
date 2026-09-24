import Foundation
import PocketCastsUtils

class DatabaseHelper {
    /// Sets up the database schema, running any required migrations.
    /// - Returns: `true` if the database was created from scratch this call (starting
    ///   schema version 0) — i.e. there were no tables to begin with.
    @discardableResult
    class func setup(queue: GRDBQueue) -> Bool {
        var databaseWasCreated = false
        do {
            try queue.dbPool.write { database in
                let db = GRDBDatabase(database: database)
                let startingSchemaVersion = db.pragmaUserVersion() ?? 0
                databaseWasCreated = startingSchemaVersion < 1

                var newSchemaVersion = startingSchemaVersion
                try upgradeIfRequired(schemaVersion: &newSchemaVersion, db: db)

                if newSchemaVersion != startingSchemaVersion {
                    FileLog.shared.addMessage("Schema update from \(startingSchemaVersion) to \(newSchemaVersion)")
                    try db.executeUpdate("PRAGMA user_version = \(newSchemaVersion)", values: nil)
                }
            }
        } catch {
            FileLog.shared.addMessage("Failed to setup database: \(error)")
        }
        return databaseWasCreated
    }

    private struct MigrationError: Error, CustomStringConvertible {
        let schemaVersion: Int
        let underlyingError: Error

        var description: String {
            "Schema update \(schemaVersion) failed: \(underlyingError)"
        }
    }

    private class func upgradeIfRequired(schemaVersion: inout Int32, db: PCDatabase) throws {
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
                throw MigrationError(schemaVersion: 1, underlyingError: error)
            }
        }
        if schemaVersion < 2 {
            do {
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_episodeStatus ON SJEpisode (episodeStatus);", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_playingStatus ON SJEpisode (playingStatus);", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS episode_keepEpisode ON SJEpisode (keepEpisode);", values: nil)

                schemaVersion = 2
            } catch {
                throw MigrationError(schemaVersion: 2, underlyingError: error)
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
                throw MigrationError(schemaVersion: 3, underlyingError: error)
            }
        }
        if schemaVersion < 4 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN pushEnabled INTEGER NOT NULL DEFAULT 1;", values: nil)
                schemaVersion = 4
            } catch {
                throw MigrationError(schemaVersion: 4, underlyingError: error)
            }
        }
        if schemaVersion < 5 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeSortOrder INTEGER NOT NULL DEFAULT 1;", values: nil)
                schemaVersion = 5
            } catch {
                throw MigrationError(schemaVersion: 5, underlyingError: error)
            }
        }
        if schemaVersion < 6 {
            do {
                try db.executeUpdate("DELETE FROM SJFilteredPlaylist WHERE manual == 1;", values: nil)
                try db.executeUpdate("DELETE FROM SJPlaylistEpisode WHERE upcoming != 1;", values: nil)
                schemaVersion = 6
            } catch {
                throw MigrationError(schemaVersion: 6, underlyingError: error)
            }
        }
        if schemaVersion < 7 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN autoAddToUpNext INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 7
            } catch {
                throw MigrationError(schemaVersion: 7, underlyingError: error)
            }
        }
        if schemaVersion < 8 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN filterHours INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 8
            } catch {
                throw MigrationError(schemaVersion: 8, underlyingError: error)
            }
        }
        if schemaVersion < 9 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastDownloadAttemptDate REAL NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS ep_down_date ON SJEpisode (lastDownloadAttemptDate);", values: nil)
                schemaVersion = 9
            } catch {
                throw MigrationError(schemaVersion: 9, underlyingError: error)
            }
        }
        if schemaVersion < 10 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN colorVersion INTEGER NOT NULL DEFAULT 1;", values: nil)
                schemaVersion = 10
            } catch {
                throw MigrationError(schemaVersion: 10, underlyingError: error)
            }
        }
        if schemaVersion < 11 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN boostVolume INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN trimSilenceAmount INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 11
            } catch {
                throw MigrationError(schemaVersion: 11, underlyingError: error)
            }
        }
        if schemaVersion < 12 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN lastColorDownloadDate REAL;", values: nil)
                schemaVersion = 12
            } catch {
                throw MigrationError(schemaVersion: 12, underlyingError: error)
            }
        }
        if schemaVersion < 13 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN autoDownloadStatus INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 13
            } catch {
                throw MigrationError(schemaVersion: 13, underlyingError: error)
            }
        }
        if schemaVersion < 14 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN playbackErrorDetails TEXT;", values: nil)
                schemaVersion = 14
            } catch {
                throw MigrationError(schemaVersion: 14, underlyingError: error)
            }
        }
        if schemaVersion < 15 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN cachedFrameCount INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 15
            } catch {
                throw MigrationError(schemaVersion: 15, underlyingError: error)
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
                throw MigrationError(schemaVersion: 16, underlyingError: error)
            }
        }
        if schemaVersion < 17 {
            do {
                try db.executeUpdate("UPDATE SJEpisode set showNotes = NULL;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionDate REAL;", values: nil)
                schemaVersion = 17
            } catch {
                throw MigrationError(schemaVersion: 17, underlyingError: error)
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
                throw MigrationError(schemaVersion: 18, underlyingError: error)
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
                throw MigrationError(schemaVersion: 20, underlyingError: error)
            }
        }
        if schemaVersion < 21 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastPlaybackInteractionSyncStatus INTEGER NOT NULL DEFAULT 1;", values: nil)
                try db.executeUpdate("UPDATE SJEpisode SET lastPlaybackInteractionSyncStatus = 0 WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0;", values: nil)

                schemaVersion = 21
            } catch {
                throw MigrationError(schemaVersion: 21, underlyingError: error)
            }
        }
        if schemaVersion < 22 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN estimatedNextEpisode REAL;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeFrequency TEXT;", values: nil)

                schemaVersion = 22
            } catch {
                throw MigrationError(schemaVersion: 22, underlyingError: error)
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
                throw MigrationError(schemaVersion: 23, underlyingError: error)
            }
        }
        if schemaVersion < 24 {
            do {
                // set any podcasts that might have been deleted to be unsubscribed instead
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN lastUpdatedAt TEXT;", values: nil)
                schemaVersion = 24
            } catch {
                throw MigrationError(schemaVersion: 24, underlyingError: error)
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
                throw MigrationError(schemaVersion: 25, underlyingError: error)
            }
        }
        if schemaVersion < 26 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN lastArchiveInteractionDate REAL NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 26
            } catch {
                throw MigrationError(schemaVersion: 26, underlyingError: error)
            }
        }
        if schemaVersion < 27 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN overrideGlobalEffects INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 27
            } catch {
                throw MigrationError(schemaVersion: 27, underlyingError: error)
            }
        }
        if schemaVersion < 28 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN autoDownloadLimit INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 28
            } catch {
                throw MigrationError(schemaVersion: 28, underlyingError: error)
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
                throw MigrationError(schemaVersion: 29, underlyingError: error)
            }
        }
        if schemaVersion < 30 {
            do {
                // since we're re-using the old database column that was for keep, clear out any legacy values that might be in there
                try db.executeUpdate("UPDATE SJPodcast SET episodeKeepSetting = 0;", values: nil)

                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN excludeFromEpisodeLimit INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 30
            } catch {
                throw MigrationError(schemaVersion: 30, underlyingError: error)
            }
        }
        if schemaVersion < 31 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN episodeGrouping INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 31
            } catch {
                throw MigrationError(schemaVersion: 31, underlyingError: error)
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
                throw MigrationError(schemaVersion: 32, underlyingError: error)
            }
        }
        if schemaVersion < 33 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN skipLast INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 33
            } catch {
                throw MigrationError(schemaVersion: 33, underlyingError: error)
            }
        }
        if schemaVersion < 34 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN fullSyncLastSyncAt TEXT;", values: nil)
                schemaVersion = 34
            } catch {
                throw MigrationError(schemaVersion: 34, underlyingError: error)
            }
        }
        if schemaVersion < 35 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN showArchived INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 35
            } catch {
                throw MigrationError(schemaVersion: 35, underlyingError: error)
            }
        }
        if schemaVersion < 36 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN filterDuration INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN longerThan INTEGER NOT NULL DEFAULT 0;", values: nil)
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN shorterThan INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 36
            } catch {
                throw MigrationError(schemaVersion: 36, underlyingError: error)
            }
        }
        if schemaVersion < 37 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN licensing INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 37
            } catch {
                throw MigrationError(schemaVersion: 37, underlyingError: error)
            }
        }
        if schemaVersion < 38 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN starredModified INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 38
            } catch {
                throw MigrationError(schemaVersion: 38, underlyingError: error)
            }
        }
        if schemaVersion < 39 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN refreshAvailable INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 39
            } catch {
                throw MigrationError(schemaVersion: 39, underlyingError: error)
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
                throw MigrationError(schemaVersion: 40, underlyingError: error)
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
                throw MigrationError(schemaVersion: 41, underlyingError: error)
            }
        }

        if schemaVersion < 42 {
            do {
                try BookmarkDataManager.createTable(in: db)

                schemaVersion = 42
            } catch {
                throw MigrationError(schemaVersion: 42, underlyingError: error)
            }
        }

        if schemaVersion < 43 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN deselectedChapters TEXT;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN settings TEXT NOT NULL DEFAULT '';", values: nil)
                schemaVersion = 43
            } catch {
                throw MigrationError(schemaVersion: 43, underlyingError: error)
            }
        }

        if schemaVersion < 44 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN deselectedChaptersModified INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 44
            } catch {
                throw MigrationError(schemaVersion: 44, underlyingError: error)
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
                throw MigrationError(schemaVersion: 45, underlyingError: error)
            }
        }

        if schemaVersion < 46 {
            do {
                try db.executeUpdate("DROP TABLE EpisodeMetadata;", values: nil)
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN metadata TEXT;", values: nil)
                schemaVersion = 46
            } catch {
                throw MigrationError(schemaVersion: 46, underlyingError: error)
            }
        }

        if schemaVersion < 47 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN contentType TEXT;", values: nil)
                try db.executeUpdate("ALTER TABLE SJUserEpisode ADD COLUMN contentType TEXT;", values: nil)
                schemaVersion = 47
            } catch {
                throw MigrationError(schemaVersion: 47, underlyingError: error)
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
                throw MigrationError(schemaVersion: 51, underlyingError: error)
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
                throw MigrationError(schemaVersion: 52, underlyingError: error)
            }
        }

        if schemaVersion < 53 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN usedCustomEffectsBefore INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 53
            } catch {
                throw MigrationError(schemaVersion: 53, underlyingError: error)
            }
        }

        if schemaVersion < 54 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN podcastHTMLDescription TEXT;", values: nil)
                schemaVersion = 54
            } catch {
                throw MigrationError(schemaVersion: 54, underlyingError: error)
            }
        }

        if schemaVersion < 55 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isPrivate INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 55
            } catch {
                throw MigrationError(schemaVersion: 55, underlyingError: error)
            }
        }

        if schemaVersion < 56 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN fundingURL TEXT;", values: nil)
                schemaVersion = 56
            } catch {
                throw MigrationError(schemaVersion: 56, underlyingError: error)
            }
        }

        if schemaVersion < 57 {
            do {
                // During the FMDB to GRDB migration, we found some users had corrupted episodes
                // with all columns set to NULL. This cleanup prevents crashes caused by those entries.
                try db.executeUpdate("DELETE FROM SJEpisode WHERE id IS NULL", values: nil)
                try db.executeUpdate("DELETE FROM SJPodcast WHERE id IS NULL", values: nil)
                schemaVersion = 57
            } catch {
                throw MigrationError(schemaVersion: 57, underlyingError: error)
            }
        }

        if schemaVersion < 58 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN rawPlaylistType INTEGER NOT NULL DEFAULT 0;", values: nil)
                schemaVersion = 58
            } catch {
                throw MigrationError(schemaVersion: 58, underlyingError: error)
            }
        }

        if schemaVersion < 59 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist DROP COLUMN rawPlaylistType;", values: nil)
                try db.executeUpdate("ALTER TABLE SJPlaylistEpisode ADD COLUMN playlist_uuid TEXT;", values: nil)
                schemaVersion = 59
            } catch {
                throw MigrationError(schemaVersion: 59, underlyingError: error)
            }
        }

        if schemaVersion < 69 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN showArchivedEpisodes BOOLEAN DEFAULT FALSE;", values: nil)
                schemaVersion = 69
            } catch {
                throw MigrationError(schemaVersion: 69, underlyingError: error)
            }
        }

        if schemaVersion < 70 {
            do {
                try db.executeUpdate("ALTER TABLE SJFilteredPlaylist ADD COLUMN playlistUpdateDate REAL;", values: nil)
                schemaVersion = 70
            } catch {
                throw MigrationError(schemaVersion: 70, underlyingError: error)
            }
        }

        if schemaVersion < 71 {
            do {
                // Indexes to optimize manual playlist queries by playlist_uuid and ordering by episodePosition
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_uuid ON SJPlaylistEpisode (playlist_uuid);", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_uuid_pos ON SJPlaylistEpisode (playlist_uuid, episodePosition);", values: nil)
                try db.executeUpdate("CREATE INDEX IF NOT EXISTS playlist_episode_playlist_uuid_episode ON SJPlaylistEpisode (playlist_uuid, episodeUuid);", values: nil)

                schemaVersion = 71
            } catch {
                throw MigrationError(schemaVersion: 71, underlyingError: error)
            }
        }

        if schemaVersion < 72 {
            do {
                try NetworkDataUsageManager.createTable(in: db)

                schemaVersion = 72
            } catch {
                throw MigrationError(schemaVersion: 72, underlyingError: error)
            }
        }

        if schemaVersion < 73 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN hasGeneratedTranscript INTEGER;", values: nil)
                schemaVersion = 73
            } catch {
                throw MigrationError(schemaVersion: 73, underlyingError: error)
            }
        }

        if schemaVersion < 74 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN isExplicit INTEGER DEFAULT 0;", values: nil)
                schemaVersion = 74
            } catch {
                throw MigrationError(schemaVersion: 74, underlyingError: error)
            }
        }

        if schemaVersion < 75 {
            do {
                try db.executeUpdate("ALTER TABLE SJEpisode ADD COLUMN hlsUrl TEXT;", values: nil)
                schemaVersion = 75
            } catch {
                throw MigrationError(schemaVersion: 75, underlyingError: error)
            }
        }

        if schemaVersion < 76 {
            do {
                try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN passage TEXT;", values: nil)
                try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN passage_location INTEGER;", values: nil)
                try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN passage_modified_date INTEGER;", values: nil)
                try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN reference_time real;", values: nil)
                try db.executeUpdate("ALTER TABLE Bookmark ADD COLUMN reference_time_modified_date INTEGER;", values: nil)
                schemaVersion = 76
            } catch {
                throw MigrationError(schemaVersion: 76, underlyingError: error)
            }
        }

        if schemaVersion < 77 {
            do {
                try db.executeUpdate("ALTER TABLE SJPodcast ADD COLUMN networkListId TEXT;", values: nil)
                schemaVersion = 77
            } catch {
                throw MigrationError(schemaVersion: 77, underlyingError: error)
            }
        }
    }
}
