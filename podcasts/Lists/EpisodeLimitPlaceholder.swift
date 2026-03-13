import Foundation

class EpisodeLimitPlaceholder: ListItem {
    let limit: Int
    let message: String

    init(limit: Int, message: String) {
        self.limit = limit
        self.message = message

        super.init()
    }

    override var differenceIdentifier: String {
        "episodeLimit"
    }

    static func == (lhs: EpisodeLimitPlaceholder, rhs: EpisodeLimitPlaceholder) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? EpisodeLimitPlaceholder else { return false }

        return limit == rhs.limit
    }
}
