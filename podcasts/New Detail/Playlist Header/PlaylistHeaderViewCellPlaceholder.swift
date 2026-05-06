class PlaylistHeaderViewCellPlaceholder: ListItem {
    override var differenceIdentifier: String {
        "playlistHeaderResult"
    }

    static func == (lhs: PlaylistHeaderViewCellPlaceholder, rhs: PlaylistHeaderViewCellPlaceholder) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        otherItem is PlaylistHeaderViewCellPlaceholder
    }
}
