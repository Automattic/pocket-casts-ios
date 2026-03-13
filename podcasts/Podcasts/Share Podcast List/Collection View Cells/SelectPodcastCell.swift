
import PocketCastsDataModel
import UIKit

class SelectPodcastCell: UICollectionViewCell {
    private let selectedOffset = 8 as CGFloat

    @IBOutlet var podcastImage: UIImageView!
    @IBOutlet var backgroundColorView: ThemeableView! {
        didSet {
            backgroundColorView.layer.cornerRadius = 4
            backgroundColorView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
            backgroundColorView.layer.shadowOffset = CGSize(width: 0, height: 1)
            backgroundColorView.layer.shadowOpacity = 0.1
            backgroundColorView.layer.shadowRadius = 2
        }
    }

    @IBOutlet var selectedOverlay: UIView!
    @IBOutlet var selectedCircle: UIImageView!
    private var podcastTitle: String?
    override var bounds: CGRect {
        didSet {
            backgroundColorView.layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        }
    }

    func populateFrom(_ podcast: Podcast) {
        ImageManager.sharedManager.loadImage(podcastUuid: podcast.uuid, imageView: podcastImage, size: .grid, showPlaceHolder: true)
        podcastTitle = podcast.title
        updateAccessibilityLabel()
    }

    func setPodcastSelected(_ selected: Bool, animated: Bool) {
        selectedOverlay.alpha = selected ? 1 : 0
        selectedCircle.image = selected ? UIImage(named: "selectcircle-tick") : UIImage(named: "selectcircle")
        updateAccessibilityLabel(isSelected: selected)
    }

    private func updateAccessibilityLabel(isSelected: Bool = false) {
        let state = isSelected ? L10n.statusSelected : L10n.statusNotSelected
        podcastImage.accessibilityLabel = (podcastTitle ?? "") + ", " + state
    }
}
