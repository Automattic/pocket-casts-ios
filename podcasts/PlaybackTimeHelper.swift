import PocketCastsDataModel

struct PlaybackTimeHelper {
    let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    /// This doesn't return the playtime in the last 7 days in a super accurate way
    /// It just looks at the played podcasts in the last 7 days and sums their
    /// total played up to time.
    /// This is not accurate but give us enough info to target users active in the last 7 days
    func playtimeLastSevenDaysInMinutes() -> Double {
        let query = "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000"

        let last1000EpisodesPlayed = dataManager.findEpisodesWhere(customWhere: query, arguments: nil)

        let date = Date()
        let sevenDaysAgo = date.sevenDaysAgo() ?? date
        let lastSevenDays = sevenDaysAgo...date

        var totalPlaytime: Double = 0
        for episode in last1000EpisodesPlayed {
            // Is the last interaction on the last 7 days?
            if lastSevenDays.contains(episode.lastPlaybackInteractionDate!) {
                totalPlaytime += episode.playedUpTo
            } else {
                break
            }
        }

        return totalPlaytime
    }
}
