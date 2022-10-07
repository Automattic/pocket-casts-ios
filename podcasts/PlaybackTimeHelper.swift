import PocketCastsDataModel

struct PlaybackTimeHelper {
    let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    /// This returns the total seconds of `playedUpTo` for episodes played in the last 7 days
    /// This DOES NOT return the accurate playtime from the last 7 days.
    func playedUpToSumInLastSevenDays() -> Double {
        let query = "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000"

        let last1000EpisodesPlayed = dataManager.findEpisodesWhere(customWhere: query, arguments: nil)

        let date = Date()
        let sevenDaysAgo = date.sevenDaysAgo() ?? date
        let lastSevenDays = sevenDaysAgo ... date

        var totalPlaytime: Double = 0
        for episode in last1000EpisodesPlayed {
            guard let lastPlaybackInteractionDate = episode.lastPlaybackInteractionDate else { continue }

            // Is the last interaction within the last 7 days?
            if lastSevenDays.contains(lastPlaybackInteractionDate) {
                totalPlaytime += episode.playedUpTo
            } else {
                break
            }
        }

        return totalPlaytime
    }
}
