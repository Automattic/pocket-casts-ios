import PocketCastsDataModel
import UIKit

class UnplayedSashOverlayView: UIView {
    private let bgImage = UIImageView()
    private let badgeLabel = UILabel()

    private var bgImageHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func populateFrom(podcast: Podcast, badgeType: BadgeType, libraryType: LibraryType) {
        updateForLibraryType(libraryType)

        updateBadge(count: podcast.cachedUnreadCount, badgeType: badgeType)
    }

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        updateForLibraryType(libraryType)

        updateBadge(count: folder.cachedUnreadCount, badgeType: badgeType)
    }

    private func updateBadge(count: Int, badgeType: BadgeType) {
        if badgeType == .latestEpisode || badgeType == .allUnplayed, count > 0 {
            bgImage.isHidden = false
            badgeLabel.isHidden = false
            if badgeType == .latestEpisode {
                badgeLabel.text = "●"
            } else {
                badgeLabel.text = count < 99 ? "\(count)" : "99"
            }
        } else {
            bgImage.isHidden = true
            badgeLabel.isHidden = true
        }
    }

    private func updateForLibraryType(_ libraryType: LibraryType) {
        if libraryType == .fourByFour {
            bgImage.image = UIImage(named: "badge4x4")
            bgImageHeightConstraint.constant = 33
        } else {
            bgImage.image = UIImage(named: "badge3x3")
            bgImageHeightConstraint.constant = 42
        }
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        bgImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bgImage)
        bgImageHeightConstraint = bgImage.heightAnchor.constraint(equalToConstant: 42)
        NSLayoutConstraint.activate([
            bgImageHeightConstraint,
            bgImage.widthAnchor.constraint(equalTo: bgImage.heightAnchor),
            bgImage.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgImage.topAnchor.constraint(equalTo: topAnchor)
        ])

        badgeLabel.font = UIFont.systemFont(ofSize: 12)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.textAlignment = .center
        addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.heightAnchor.constraint(equalToConstant: 20),
            badgeLabel.widthAnchor.constraint(equalToConstant: 20),
            badgeLabel.centerYAnchor.constraint(equalTo: bgImage.centerYAnchor, constant: -8),
            badgeLabel.centerXAnchor.constraint(equalTo: bgImage.centerXAnchor, constant: 8)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)

        updateBadgeColors()
    }

    @objc private func themeDidChange() {
        updateBadgeColors()
    }

    private func updateBadgeColors() {
        bgImage.tintColor = ThemeColor.support05()
        badgeLabel.textColor = ThemeColor.contrast01()
    }
}
