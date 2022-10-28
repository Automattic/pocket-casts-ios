import PocketCastsDataModel
import UIKit

class PlaylistColorChooserCell: ThemeableCell {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var separatorView: ThemeDividerView!

    private var colors = [UIColor]()
    private let edgePadding = 0
    private let viewSize = 58
    private let tickSize = 24

    var playlist: EpisodeFilter? {
        didSet {
            setupScrollView()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}

    func showSeperatorView() {
        separatorView.isHidden = false
    }

    private func setupScrollView() {
        scrollView.removeAllSubviews()
        reloadColors()
        let colorViewSize = 42
        let colorViewOffset = Double(viewSize - colorViewSize) / 2.0

        let playlistColor = playlist!.playlistColor()
        for i in 0 ..< colors.count {
            let containerView = UIView(frame: CGRect(x: edgePadding + (viewSize * i), y: 0, width: viewSize, height: viewSize))

            let colorView = UIView(frame: CGRect(x: Int(colorViewOffset), y: Int(colorViewOffset), width: colorViewSize, height: colorViewSize))
            colorView.backgroundColor = colors[i]
            colorView.layer.cornerRadius = CGFloat(colorViewSize / 2)
            containerView.addSubview(colorView)

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PlaylistColorChooserCell.colorTapped(_:)))
            containerView.addGestureRecognizer(tapRecognizer)

            if EpisodeFilter.indexOf(color: playlistColor) == i {
                let tickOffset = Double(viewSize - tickSize) / 2.0

                let tickView = UIImageView(frame: CGRect(x: Int(tickOffset), y: Int(tickOffset), width: tickSize, height: tickSize))

                tickView.image = UIImage(named: "tick")
                tickView.tintColor = UIColor.white
                containerView.addSubview(tickView)
                colorView.transform = CGAffineTransform(scaleX: 1.14, y: 1.14)
            } else {
                colorView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }

            scrollView.addSubview(containerView)
            containerView.accessibilityLabel = L10n.accessibilityPlaylistColor(i)
        }
    }

    @objc func colorTapped(_ sender: UITapGestureRecognizer) {
        let locationTapped = sender.location(in: scrollView)
        let indexTapped = (Int(locationTapped.x) - edgePadding) / viewSize
        if indexTapped >= colors.count || indexTapped < 0 {
            return
        }

        playlist!.setPlaylistColor(color: colors[indexTapped])
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistTempChange)
    }

    override func handleThemeDidChange() {
        reloadColors()
    }

    func reloadColors() {
        colors = [AppTheme.playlistRedColor(), AppTheme.playlistBlueColor(), AppTheme.playlistGreenColor(), AppTheme.playlistPurpleColor(), AppTheme.playlistYellowColor()]
    }
}
