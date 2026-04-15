import Foundation
import PocketCastsDataModel

public class DataConverter {
    public class func convert(syncInfoEpisodes: [EpisodeSyncInfo]) -> [EpisodeBasicData] {
        var allConvertedEpisodes = [EpisodeBasicData]()
        for episodeSyncInfo in syncInfoEpisodes {
            var convertedData = EpisodeBasicData()
            convertedData.uuid = episodeSyncInfo.uuid
            convertedData.duration = episodeSyncInfo.duration
            convertedData.playingStatus = episodeSyncInfo.playingStatus
            convertedData.playedUpTo = episodeSyncInfo.playedUpTo
            convertedData.isArchived = episodeSyncInfo.isArchived
            convertedData.starred = episodeSyncInfo.starred
            convertedData.deselectedChapters = episodeSyncInfo.deselectedChapters

            allConvertedEpisodes.append(convertedData)
        }

        return allConvertedEpisodes
    }
}
