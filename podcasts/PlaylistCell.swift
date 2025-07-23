import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        iconStyle = .primaryIcon02

        updateColor()

        separatorInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        ensureCorrectReorderColor()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        ensureCorrectReorderColor()
    }

    private func ensureCorrectReorderColor() {
        let theme = themeOverride ?? Theme.sharedTheme.activeTheme

        overrideUserInterfaceStyle = theme.isDark ? .dark : .light
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(playlist: EpisodeFilter) {
        contentConfiguration = UIHostingConfiguration {
            PlaylistCellView(viewModel: PlaylistCellViewModel(playlist: playlist))
                .environmentObject(Theme.sharedTheme)
                .frame(maxWidth: .infinity, minHeight: 81.0, alignment: .leading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
    }
}
