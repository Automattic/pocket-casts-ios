public enum WatchConstants {
    public enum Keys {
        public static let messageVersion = "id"
        public static let loginChanged = "loginChanged"

        public static let filters = "filters"
        public static let nowPlayingInfo = "nowPlaying"
        public static let nowPlayingEpisode = "episode"
        public static let nowPlayingStatus = "status"
        public static let nowPlayingCurrentTime = "upto"
        public static let nowPlayingDuration = "duration"
        public static let nowPlayingColor = "color"
        public static let nowPlayingUpNextCount = "upcount"
        public static let nowPlayingSkipForwardAmount = "skip_back"
        public static let nowPlayingSkipBackAmount = "skip_fwd"
        public static let nowPlayingHasChapters = "chapters"
        public static let nowPlayingChapterTitle = "chapterTitle"
        public static let nowPlayingTrimSilence = "trim"
        public static let nowPlayingVolumeBoost = "boost"
        public static let nowPlayingSubtitle = "subTitle"
        public static let nowPlayingSpeed = "speed"
        public static let upNextInfo = "upNext"
        public static let lastUpdateTime = "last_update"

        public static let filterTitle = "title"
        public static let filterUuid = "uuid"
        public static let filterIcon = "icon"

        public static let episodeTypeKey = "type"
        public static let episodeSerialisedKey = "serialized"

        public static let podcastSettings = "podcastSettings"
        public static let podcastUuid = "uuid"
        public static let podcastCustomPosition = "podcastCustomPosition"
        public static let podcastEpisodeGrouping = "episodeGrouping"
        public static let podcastEpisodeSortOrder = "episodeSortOrder"
        public static let podcastAutoArchiveEpisodeLimit = "autoArchiveEpisodeLimit"
        public static let podcastAutoArchivePlayedAfter = "podcastAutoArchivePlayedAfter"
        public static let podcastOverrideGlobalArchive = "podcastOverrideGlobalArchive"

        public static let autoArchivePlayedAfter = "autoArchivePlayedAfter"
        public static let autoArchiveStarredEpisodes = "autoArchiveStarredEpisodes"

        public static let upNextDownloadEpisodeCount = "upNextDownloadEpisodeCount"
        public static let upNextAutoDeleteEpisodeCount = "upNextAutoDeleteEpisodeCount"
    }

    public enum PlayingStatus {
        public static let playing = "playing"
        public static let paused = "paused"
    }

    public enum Values {
        public static let messageVersion = "wappv4"
        public static let userEpisodeFakePodcastId = "da7aba5e-f11e-f11e-f11e-da7aba5ef11e"
    }

    public enum UserDefaults {
        public static let data = "data"
        public static let lastPage = "lastPage_v2"
        public static let lastContext = "lastContext_v2"
        public static let lastSubscriptionStatusTime = "lastSubscriptionStatusTime"
        public static let lastDataTime = "lastDataTime"
    }

    public enum Notifications {
        public static let dataUpdated = "dataUpdated"
        public static let loginStatusUpdated = "loginStatusUpdated"
    }

    public enum Interface {
        public static let podcastIconSize: CGFloat = 23
    }

    public enum Messages {
        public static let messageType = "messageType"

        enum LogFileRequest {
            public static let type = "logFileRequest"
            public static let logContents = "logFile"
        }

        enum SignificantSyncableUpdate {
            public static let type = "sigSyncUpdate"
        }

        enum MinorSyncableUpdate {
            public static let type = "minSyncUpdate"
        }

        enum DataRequest {
            public static let type = "dataRequest"
        }

        enum FilterRequest {
            public static let type = "filterRequest"
            public static let filterUuid = "uuid"
        }

        enum EpisodeRequest {
            public static let type = "episodeRequest"
            public static let episodeUuid = "uuid"
        }

        enum FilterResponse {
            public static let episodes = "episodes"
        }

        enum DownloadsRequest {
            public static let type = "downloadRequest"
        }

        enum DownloadsResponse {
            public static let episodes = "episodes"
        }

        enum UserEpisodeRequest {
            public static let type = "userEpisodeRequest"
        }

        enum UserEpisodeResponse {
            public static let episodes = "episodes"
        }

        enum PlayEpisodeRequest {
            public static let type = "playEpisodeRequest"
            public static let episodeUuid = "uuid"
            public static let playlist = "playlist"
        }

        enum PlayPauseRequest {
            public static let type = "playPause"
        }

        enum SkipBackRequest {
            public static let type = "skipBack"
        }

        enum SkipForwardRequest {
            public static let type = "skipForward"
        }

        enum StarRequest {
            public static let type = "starRequest"
            public static let star = "star"
            public static let episodeUuid = "uuid"
        }

        enum MarkPlayedRequest {
            public static let type = "playedRequest"
            public static let episodeUuid = "uuid"
        }

        enum MarkUnplayedRequest {
            public static let type = "unplayedRequest"
            public static let episodeUuid = "uuid"
        }

        enum DownloadRequest {
            public static let type = "downloadRequest"
            public static let episodeUuid = "uuid"
        }

        enum StopDownloadRequest {
            public static let type = "stopDownloadRequest"
            public static let episodeUuid = "uuid"
        }

        enum DeleteDownloadRequest {
            public static let type = "deleteDownloadRequest"
            public static let episodeUuid = "uuid"
        }

        enum ArchiveRequest {
            public static let type = "archiveRequest"
            public static let episodeUuid = "uuid"
        }

        enum UnarchiveRequest {
            public static let type = "unarchiveRequest"
            public static let episodeUuid = "uuid"
        }

        enum AddToUpNextRequest {
            public static let type = "addToUpNextRequest"
            public static let episodeUuid = "uuid"
            public static let toTop = "toTop"
        }

        enum RemoveFromUpNextRequest {
            public static let type = "removeFromUpNextRequest"
            public static let episodeUuid = "uuid"
        }

        enum ClearUpNextRequest {
            public static let type = "clearUpNext"
        }

        enum ChangeChapterRequest {
            public static let type = "changeChapterRequest"
            public static let nextChapter = "next"
        }

        enum IncreaseSpeedRequest {
            public static let type = "increaseSpeedRequest"
        }

        enum DecreaseSpeedRequest {
            public static let type = "decreaseSpeedRequest"
        }

        enum ChangeSpeedIntervalRequest {
            public static let type = "changeSpeedRequest"
        }

        enum TrimSilenceRequest {
            public static let type = "trimSilenceRequest"
            public static let enabled = "enabled"
        }

        enum VolumeBoostRequest {
            public static let type = "volumeBoostRequest"
            public static let enabled = "enabled"
        }

        enum LoginDetailsRequest {
            public static let type = "loginDetailsRequest"
        }

        enum LoginDetailsResponse {
            public static let username = "username"
            public static let password = "password"
            public static let refreshToken = "refreshToken"
        }
    }
}
