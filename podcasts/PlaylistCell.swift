import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistCell"

    let viewModel = PlaylistCellViewModel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let rowView = PlaylistCellView(viewModel: viewModel).themedUIView
        rowView.backgroundColor = .clear
        contentView.addSubview(rowView)

        rowView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
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

    func configure(playlist: EpisodeFilter, resetConfiguration: Bool) {
        if !resetConfiguration {
            return
        }
        viewModel.set(playlist: playlist)
    }
}
