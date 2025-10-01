import SwiftUI
import PocketCastsDataModel

class PlaylistEpisodePreviewCell: ThemeableCell {
    static let reuseIdentifier = "PlaylistEpisodePreviewCell"

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

    func set(episode: Episode) {
        contentConfiguration = UIHostingConfiguration {
            PlaylistEpisodePreviewRowView(
                episode: episode,
                hideSeparator: true
            )
            .environmentObject(Theme.sharedTheme)
            .frame(maxWidth: .infinity, minHeight: 80.0, alignment: .leading)
            .padding(.leading, 16.0)
            .padding(.vertical, 5.0)
        }
        .margins(.horizontal, 0)
        .margins(.vertical, 0)

        separatorView.backgroundColor = AppTheme.colorForStyle(.primaryUi05)
        bringSubviewToFront(separatorView)
    }
}
