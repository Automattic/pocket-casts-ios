import Foundation
import PocketCastsDataModel

struct ShelfLoadState {
    private var lastShelfActionsLoaded: [PlayerAction]?
    private var lastShelfEpisodeUuid: String?
    private var effectsAreOn = false
    private var sleepTimerIsOn = false
    private var episodeIsStarred = false
    private var episodeStatus: Int32 = 0
    private var videoToggleAvailable = false
    private var videoRenderingEnabled = true

    mutating func updateRequired(shelfActions: [PlayerAction], episodeUuid: String, effectsOn: Bool, sleepTimerOn: Bool, episodeStarred: Bool, episodeStatus: Int32, videoToggleAvailable: Bool, videoRenderingEnabled: Bool) -> Bool {
        if lastShelfActionsLoaded == shelfActions, lastShelfEpisodeUuid == episodeUuid, effectsAreOn == effectsOn, sleepTimerIsOn == sleepTimerOn, episodeIsStarred == episodeStarred, episodeStatus == self.episodeStatus, self.videoToggleAvailable == videoToggleAvailable, self.videoRenderingEnabled == videoRenderingEnabled {
            return false
        }

        lastShelfActionsLoaded = shelfActions
        lastShelfEpisodeUuid = episodeUuid
        effectsAreOn = effectsOn
        sleepTimerIsOn = sleepTimerOn
        episodeIsStarred = episodeStarred
        self.episodeStatus = episodeStatus
        self.videoToggleAvailable = videoToggleAvailable
        self.videoRenderingEnabled = videoRenderingEnabled

        return true
    }
}
