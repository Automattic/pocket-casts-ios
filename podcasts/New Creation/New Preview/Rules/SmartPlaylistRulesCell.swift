import UIKit
import SwiftUI

class SmartPlaylistRulesCell: ThemeableCell {
    static let reuseIdentifier = "SmartPlaylistRulesCellIdentifier"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .none

        self.style = .primaryUi01

        updateColor()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: PlaylistPreviewViewModel) {
        contentConfiguration = UIHostingConfiguration {
            SmartPlaylistRulesView(
                viewModel: viewModel
            )
            .environmentObject(Theme.sharedTheme)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)
    }
}
