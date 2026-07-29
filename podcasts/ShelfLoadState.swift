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
    private var videoRendering = true

    mutating func updateRequired(shelfActions: [PlayerAction], episodeUuid: String, effectsOn: Bool, sleepTimerOn: Bool, episodeStarred: Bool, episodeStatus: Int32, videoToggleAvailable: Bool, videoRendering: Bool) -> Bool {
        if lastShelfActionsLoaded == shelfActions, lastShelfEpisodeUuid == episodeUuid, effectsAreOn == effectsOn, sleepTimerIsOn == sleepTimerOn, episodeIsStarred == episodeStarred, episodeStatus == self.episodeStatus, self.videoToggleAvailable == videoToggleAvailable, self.videoRendering == videoRendering {
            return false
        }

        lastShelfActionsLoaded = shelfActions
        lastShelfEpisodeUuid = episodeUuid
        effectsAreOn = effectsOn
        sleepTimerIsOn = sleepTimerOn
        episodeIsStarred = episodeStarred
        self.episodeStatus = episodeStatus
        self.videoToggleAvailable = videoToggleAvailable
        self.videoRendering = videoRendering

        return true
    }
}
