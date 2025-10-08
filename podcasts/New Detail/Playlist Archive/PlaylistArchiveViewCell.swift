import SwiftUI

class PlaylistArchiveViewCellPlaceholder: ListItem {
    override var differenceIdentifier: String {
        "playlistArchiveViewCellResult"
    }

    static func == (lhs: PlaylistArchiveViewCellPlaceholder, rhs: PlaylistArchiveViewCellPlaceholder) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        otherItem is PlaylistArchiveViewCellPlaceholder
    }
}

class PlaylistArchiveViewCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistArchiveViewCellIdentifier"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .none
        selectionStyle = .none

        setClearBackground()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setClearBackground()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setClearBackground()
    }

    func configure(
        viewModel: PlaylistDetailViewModel,
        isSelected: Binding<Bool>
    ) {
        contentConfiguration = UIHostingConfiguration {
            PlaylistArchiveView(
                episodesCount: viewModel.archivedEpisodesCount,
                isSelected: isSelected
            )
                .environmentObject(Theme.sharedTheme)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
        .background(.clear)
    }

    private func setClearBackground() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}
