import UIKit
import SwiftUI
import PocketCastsDataModel

class PlaylistCell: ThemeableCell {
    typealias PlaylistCellType = PlaylistCellViewModel.DisplayType

    static let reuseIdentifier = "PlaylistCell"
    static let cellHeight = 81.0
    static let emptyPlaylist = EpisodeFilter()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        self.style = .primaryUi01
        iconStyle = .primaryIcon02

        updateColor()

        separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        layoutMargins = .zero
        preservesSuperviewLayoutMargins = false

        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0)
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

    func configure(
        cellType: PlaylistCellType = .count,
        playlist: EpisodeFilter,
        isLastRow: Bool,
        isSelected: Binding<Bool> = .constant(false),
        canBeDisabled: Bool = false
    ) {
        accessoryType = cellType == .count ? .disclosureIndicator : .none

        contentConfiguration = UIHostingConfiguration {
            PlaylistCellView(
                viewModel: PlaylistCellViewModel(
                    playlist: playlist,
                    displayType: cellType
                ),
                isSelected: isSelected,
                canBeDisabled: canBeDisabled
            )
            .environmentObject(Theme.sharedTheme)
            .frame(maxWidth: .infinity, minHeight: Self.cellHeight, alignment: .leading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)

        separatorView.isHidden = isLastRow
        separatorView.backgroundColor = AppTheme.colorForStyle(.primaryUi05)
        bringSubviewToFront(separatorView)
    }

    func configureAddPlaylistCell() {
        accessoryType = .none

        contentConfiguration = UIHostingConfiguration {
            PlaylistCellView(
                viewModel: PlaylistCellViewModel(
                    playlist: Self.emptyPlaylist,
                    displayType: .addNew
                ),
                isSelected: .constant(false)
            )
            .environmentObject(Theme.sharedTheme)
            .frame(maxWidth: .infinity, minHeight: Self.cellHeight, alignment: .leading)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)

        separatorView.isHidden = true
    }
}
