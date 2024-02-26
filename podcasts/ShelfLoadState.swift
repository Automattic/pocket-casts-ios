import Foundation
import PocketCastsDataModel

struct ShelfLoadState {
    private var lastShelfActionsLoaded: [PlayerAction]?
    private var lastShelfEpisodeUuid: String?
    private var effectsAreOn = false
    private var sleepTimerIsOn = false
    private var episodeIsStarred = false

    mutating func updateRequired(shelfActions: [PlayerAction], episodeUuid: String, effectsOn: Bool, sleepTimerOn: Bool, episodeStarred: Bool) -> Bool {
        if lastShelfActionsLoaded == shelfActions, lastShelfEpisodeUuid == episodeUuid, effectsAreOn == effectsOn, sleepTimerIsOn == sleepTimerOn, episodeIsStarred == episodeStarred {
            return false
        }

        lastShelfActionsLoaded = shelfActions
        lastShelfEpisodeUuid = episodeUuid
        effectsAreOn = effectsOn
        sleepTimerIsOn = sleepTimerOn
        episodeIsStarred = episodeStarred

        return true
    }
}
