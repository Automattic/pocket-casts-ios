class PlaylistArchiveViewCellPlaceholder: ListItem {
    let archived: Int
    let showArchived: Bool

    init(archived: Int, showArchived: Bool) {
        self.archived = archived
        self.showArchived = showArchived
        super.init()
    }

    override var differenceIdentifier: String {
        "playlistArchiveViewCellResult"
    }

    static func == (lhs: PlaylistArchiveViewCellPlaceholder, rhs: PlaylistArchiveViewCellPlaceholder) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? PlaylistArchiveViewCellPlaceholder else { return false }

        return archived == rhs.archived && showArchived == rhs.showArchived
    }
}
