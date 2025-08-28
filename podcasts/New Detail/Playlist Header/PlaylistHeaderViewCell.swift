import UIKit
import SwiftUI

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


class PlaylistHeaderViewCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistHeaderViewCellIdentifier"

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

    func configure(viewModel: PlaylistDetailViewModel) {
        contentConfiguration = UIHostingConfiguration {
            PlaylistHeaderView(viewModel: viewModel)
                .environmentObject(Theme.sharedTheme)
                .frame(maxWidth: .infinity, minHeight: 335, alignment: .leading)
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
