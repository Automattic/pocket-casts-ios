import Foundation
import PocketCastsDataModel

extension Array where Element == Episode {
    func toListEpisodes(
        tintColor: UIColor = AppTheme.appTintColor(),
        playbackManager: PlaybackManager = .shared
    ) -> [ListEpisode] {
        return map {
            let isInUpNext = playbackManager.inUpNext(episode: $0)
            return ListEpisode(episode: $0, tintColor: tintColor, isInUpNext: isInUpNext)
        }
    }
}
