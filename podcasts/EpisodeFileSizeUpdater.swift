import AVFoundation
import Foundation
import PocketCastsDataModel

class EpisodeFileSizeUpdater {
    class func updateEpisodeDuration(episode: BaseEpisode?) {
        guard let episode = episode else { return }

        let fileLocation = episode.pathToDownloadedFile(pathFinder: DownloadManager.shared)
        let url = URL(fileURLWithPath: fileLocation)
        let asset = AVURLAsset(url: url)

        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            let status = asset.statusOfValue(forKey: "duration", error: nil)
            if status == .loaded {
                let calculatedDuration = CMTimeGetSeconds(asset.duration)
                if calculatedDuration < 10 || calculatedDuration > 36000 { return } // duration is too short or too long to be a podcast eg: less than 10 seconds or more than 10 hours

                let currentDuration = episode.duration
                if Int(currentDuration) == Int(calculatedDuration) { return } // we already have the correct duration

                var syncChanges = true
                if abs(currentDuration - calculatedDuration) < 30 {
                    // only a minor change so just update the db but don't bother syncing
                    syncChanges = false
                }

                DataManager.sharedManager.saveEpisode(duration: calculatedDuration, episode: episode, updateSyncFlag: syncChanges)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDurationChanged, object: episode.uuid)
            }
        }
    }
}
