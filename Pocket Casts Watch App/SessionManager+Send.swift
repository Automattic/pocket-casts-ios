import Foundation
import PocketCastsDataModel
import WatchConnectivity
import WatchKit

extension SessionManager {
    func significantSyncableUpdate() {
        sendResponseless(messageType: WatchConstants.Messages.SignificantSyncableUpdate.type)
    }

    func minorSyncableUpdate() {
        sendResponseless(messageType: WatchConstants.Messages.MinorSyncableUpdate.type)
    }

    func play(episode: BaseEpisode, playlist: AutoplayHelper.Playlist?) {
        if !WCSession.default.isReachable { return }

        let playEpisodeRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.PlayEpisodeRequest.type, WatchConstants.Messages.PlayEpisodeRequest.episodeUuid: episode.uuid,
            WatchConstants.Messages.PlayEpisodeRequest.playlist: (try? JSONEncoder().encode(playlist)) as Any] as [String: Any]
        WCSession.default.sendMessage(playEpisodeRequest, replyHandler: nil)
    }

    func togglePlayPause() {
        sendResponseless(messageType: WatchConstants.Messages.PlayPauseRequest.type)
    }

    func skipBack() {
        sendResponseless(messageType: WatchConstants.Messages.SkipBackRequest.type)
    }

    func skipForward() {
        sendResponseless(messageType: WatchConstants.Messages.SkipForwardRequest.type)
    }

    func clearUpNext() {
        sendResponseless(messageType: WatchConstants.Messages.ClearUpNextRequest.type)
    }

    func setEpisodeStarred(starred: Bool, episodeUuid: String) {
        let starRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.StarRequest.type,
            WatchConstants.Messages.StarRequest.star: starred,
            WatchConstants.Messages.StarRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(starRequest, replyHandler: nil)
    }

    func deleteDownload(episodeUuid: String) {
        let deleteDownloadRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.DeleteDownloadRequest.type,
            WatchConstants.Messages.DeleteDownloadRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(deleteDownloadRequest, replyHandler: nil)
    }

    func downloadEpisode(episodeUuid: String) {
        let downloadRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.DownloadRequest.type,
            WatchConstants.Messages.DownloadRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(downloadRequest, replyHandler: nil)
    }

    func stopEpisodeDownload(episodeUuid: String) {
        let stopDownloadRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.StopDownloadRequest.type,
            WatchConstants.Messages.StopDownloadRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(stopDownloadRequest, replyHandler: nil)
    }

    func archiveEpisode(episodeUuid: String) {
        let archiveRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.ArchiveRequest.type,
            WatchConstants.Messages.ArchiveRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(archiveRequest, replyHandler: nil)
    }

    func unarchiveEpisode(episodeUuid: String) {
        let unarchiveRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.UnarchiveRequest.type,
            WatchConstants.Messages.UnarchiveRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(unarchiveRequest, replyHandler: nil)
    }

    func markPlayed(episodeUuid: String) {
        let markPlayedRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.MarkPlayedRequest.type,
            WatchConstants.Messages.MarkPlayedRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(markPlayedRequest, replyHandler: nil)
    }

    func markUnplayed(episodeUuid: String) {
        let markUnplayedRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.MarkUnplayedRequest.type,
            WatchConstants.Messages.MarkUnplayedRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(markUnplayedRequest, replyHandler: nil)
    }

    func changeChapter(next: Bool) {
        let changeChapterRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.ChangeChapterRequest.type,
            WatchConstants.Messages.ChangeChapterRequest.nextChapter: next
        ] as [String: Any]
        WCSession.default.sendMessage(changeChapterRequest, replyHandler: nil)
    }

    func decreasePlaybackSpeed() {
        let decreaseSpeedRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.DecreaseSpeedRequest.type] as [String: Any]
        WCSession.default.sendMessage(decreaseSpeedRequest, replyHandler: nil)
    }

    func changeSpeedInterval() {
        let changeSpeedIntervalRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.ChangeSpeedIntervalRequest.type] as [String: Any]
        WCSession.default.sendMessage(changeSpeedIntervalRequest, replyHandler: nil)
    }

    func increasePlaybackSpeed() {
        let increaseSpeedRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.IncreaseSpeedRequest.type] as [String: Any]
        WCSession.default.sendMessage(increaseSpeedRequest, replyHandler: nil)
    }

    func setVolumeBoost(enabled: Bool) {
        let volumeBoostRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.VolumeBoostRequest.type,
            WatchConstants.Messages.VolumeBoostRequest.enabled: enabled
        ] as [String: Any]
        WCSession.default.sendMessage(volumeBoostRequest, replyHandler: nil)
    }

    func setTrimSilence(enabled: Bool) {
        let trimSilenceRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.TrimSilenceRequest.type,
            WatchConstants.Messages.TrimSilenceRequest.enabled: enabled
        ] as [String: Any]
        WCSession.default.sendMessage(trimSilenceRequest, replyHandler: nil)
    }

    func addToUpNext(episodeUuid: String, toTop: Bool) {
        let addToUpNextRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.AddToUpNextRequest.type,
            WatchConstants.Messages.AddToUpNextRequest.episodeUuid: episodeUuid,
            WatchConstants.Messages.AddToUpNextRequest.toTop: toTop
        ] as [String: Any]
        WCSession.default.sendMessage(addToUpNextRequest, replyHandler: nil)
    }

    func removeFromUpNext(episodeUuid: String) {
        let addToUpNextRequest = [
            WatchConstants.Messages.messageType: WatchConstants.Messages.RemoveFromUpNextRequest.type,
            WatchConstants.Messages.RemoveFromUpNextRequest.episodeUuid: episodeUuid
        ] as [String: Any]
        WCSession.default.sendMessage(addToUpNextRequest, replyHandler: nil)
    }

    func requestEpisode(uuid: String, onReply: @escaping ((BaseEpisode?) -> Void), onError: (() -> Void)? = nil) {
        if !WCSession.default.isReachable {
            onError?()
            return
        }

        let episodeRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.EpisodeRequest.type, WatchConstants.Messages.EpisodeRequest.episodeUuid: uuid] as [String: Any]
        WCSession.default.sendMessage(episodeRequest, replyHandler: { response in
            let episode = WatchDataManager.convertToEpisode(json: response)
            onReply(episode)
        }) { _ in
            onError?()
        }
    }

    func requestContents(filter: WatchFilter, replyHandler: (([BaseEpisode]) -> Swift.Void)?, errorHandler: (() -> Swift.Void)? = nil) {
        if !WCSession.default.isReachable {
            errorHandler?()
            return
        }

        let filterRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.FilterRequest.type, WatchConstants.Messages.FilterRequest.filterUuid: filter.uuid] as [String: Any]
        WCSession.default.sendMessage(filterRequest, replyHandler: { episodesData in
            let episodes = WatchDataManager.convertToEpisodeList(data: episodesData)
            replyHandler?(episodes)
        }) { _ in
            errorHandler?()
        }
    }

    func requestDownloadedEpisodes(replyHandler: (([BaseEpisode]) -> Swift.Void)?, errorHandler: (() -> Swift.Void)? = nil) {
        if !WCSession.default.isReachable {
            errorHandler?()
            return
        }

        let downloadRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.DownloadsRequest.type]
        WCSession.default.sendMessage(downloadRequest, replyHandler: { episodesData in
            let episodes = WatchDataManager.convertToEpisodeList(data: episodesData)
            replyHandler?(episodes)
        }) { _ in
            errorHandler?()
        }
    }

    func requestUserEpisodes(replyHandler: (([BaseEpisode]) -> Swift.Void)?, errorHandler: (() -> Swift.Void)? = nil) {
        if !WCSession.default.isReachable {
            errorHandler?()
            return
        }

        let request = [WatchConstants.Messages.messageType: WatchConstants.Messages.UserEpisodeRequest.type]
        WCSession.default.sendMessage(request, replyHandler: { episodesData in
            let episodes = WatchDataManager.convertToEpisodeList(data: episodesData)
            replyHandler?(episodes)
        }) { _ in
            errorHandler?()
        }
    }

    private func sendResponseless(messageType: String) {
        if !WCSession.default.isReachable { return }

        let message = [WatchConstants.Messages.messageType: messageType]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }
}
