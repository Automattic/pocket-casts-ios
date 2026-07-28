import PocketCastsDataModel
import UIKit

class SelectedPodcastCell: UICollectionViewCell {
    @IBOutlet var podcastImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.layer.cornerRadius = 4
        contentView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 2
    }

    override var bounds: CGRect {
        didSet {
            contentView.layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        }
    }

    func populateFrom(_ podcast: Podcast) {
        ImageManager.sharedManager.loadImage(podcastUuid: podcast.uuid, imageView: podcastImage, size: .grid, showPlaceHolder: true)
        podcastImage.accessibilityLabel = podcast.title
    }
}
