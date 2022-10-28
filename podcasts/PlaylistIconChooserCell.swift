import PocketCastsDataModel
import UIKit

class PlaylistIconChooserCell: ThemeableCell {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var separatorView: ThemeDividerView!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    var filterToEdit: EpisodeFilter!
    private let viewSize = 58
    private let edgePadding = 0
    private let imageSize = 24 as Double
    let iconViewSize = 42
    var selectionHandler: ((Int32) -> Void) = { _ in }
    var selectedColor: UIColor!

    func setupWithTintColor(tintColor: UIColor, selectedIcon: Int32, selectHandler: @escaping ((Int32) -> Void)) {
        scrollView.removeAllSubviews()
        let iconViewOffset = Double(viewSize - iconViewSize) / 2.0
        let imageOffset = (Double(viewSize) - imageSize) / 2.0

        scrollView.contentSize = CGSize(width: (edgePadding + viewSize) * EpisodeFilter.iconTypeCount, height: viewSize)

        for i in 0 ..< EpisodeFilter.iconTypeCount {
            let containerView = UIView(frame: CGRect(x: edgePadding * 2 + (viewSize * i), y: 0, width: viewSize, height: viewSize))

            let circleView = UIView(frame: CGRect(x: Int(iconViewOffset), y: Int(iconViewOffset), width: iconViewSize, height: iconViewSize))

            circleView.layer.cornerRadius = CGFloat(iconViewSize / 2)
            containerView.addSubview(circleView)

            selectedColor = tintColor
            let indexOfTintColor = EpisodeFilter.indexOf(color: tintColor)
            let currentIcon = (indexOfTintColor + (EpisodeFilter.iconsPerType * i))
            let image = EpisodeFilter.imageForPlaylistIcon(icon: PlaylistIcon(rawValue: Int32(currentIcon))!)
            let iconImageView = UIImageView(image: image)
            iconImageView.frame = CGRect(x: imageOffset, y: imageOffset, width: imageSize, height: imageSize as Double)

            containerView.addSubview(iconImageView)

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(iconTapped(_:)))
            containerView.addGestureRecognizer(tapRecognizer)
            selectionHandler = selectHandler

            if currentIcon == selectedIcon {
                iconImageView.transform = CGAffineTransform(scaleX: 1.14, y: 1.14)
                iconImageView.tintColor = UIColor.white
                circleView.backgroundColor = filterToEdit.playlistColor()
                circleView.transform = CGAffineTransform(scaleX: 1.19, y: 1.19)
            } else {
                iconImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                iconImageView.tintColor = ThemeColor.primaryIcon02()
                circleView.backgroundColor = UIColor.clear
                circleView.layer.borderColor = ThemeColor.primaryIcon02().cgColor
                circleView.layer.borderWidth = 1
            }
            scrollView.addSubview(containerView)
        }
    }

    @objc func iconTapped(_ sender: UITapGestureRecognizer) {
        guard let tintColor = selectedColor else { return }
        let locationTapped = sender.location(in: scrollView)
        let indexTapped = (Int(locationTapped.x) - edgePadding) / viewSize
        if indexTapped >= EpisodeFilter.iconTypeCount || indexTapped < 0 {
            return
        }

        let indexOfTintColor = EpisodeFilter.indexOf(color: tintColor)
        let selectedIcon = (indexOfTintColor + (EpisodeFilter.iconsPerType * indexTapped))
        selectionHandler(Int32(selectedIcon))
    }

    func showSeperatorView() {
        separatorView.isHidden = false
    }
}
