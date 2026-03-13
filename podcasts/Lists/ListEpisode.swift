import Foundation
import PocketCastsDataModel

class ListEpisode: ListItem {
    let episode: Episode
    let tintColor: UIColor
    let isInUpNext: Bool

    init(episode: Episode, tintColor: UIColor, isInUpNext: Bool) {
        self.episode = episode
        self.tintColor = tintColor
        self.isInUpNext = isInUpNext

        super.init()
    }

    override var differenceIdentifier: String {
        episode.uuid
    }

    static func == (lhs: ListEpisode, rhs: ListEpisode) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    // list episodes are considered equal only if the things that represent them in a list haven't changed
    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? ListEpisode else { return false }

        return episode.uuid == rhs.episode.uuid &&
            episode.episodeStatus == rhs.episode.episodeStatus &&
            episode.playingStatus == rhs.episode.playingStatus &&
            episode.playedUpTo == rhs.episode.playedUpTo &&
            episode.duration == rhs.episode.duration &&
            episode.archived == rhs.episode.archived &&
            episode.keepEpisode == rhs.episode.keepEpisode &&
            episode.sizeInBytes == rhs.episode.sizeInBytes &&
            tintColor == rhs.tintColor &&
            isInUpNext == rhs.isInUpNext
    }
}

extension ListEpisode: Identifiable, Hashable {
    var id: String {
        episode.uuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
