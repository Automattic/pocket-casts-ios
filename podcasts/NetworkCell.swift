import PocketCastsServer
import PocketCastsUtils
import UIKit

class NetworkCell: UICollectionViewCell {
    @IBOutlet var networkImage: UIImageView! {
        didSet {
            networkImage.backgroundColor = AppTheme.extraContentBorderColor()
        }
    }

    @IBOutlet var shadowView: UIView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
        shadowView.layer.shadowOpacity = 0.1
        shadowView.layer.shadowRadius = 2
        shadowView.layer.cornerRadius = 4
    }

    override var isHighlighted: Bool {
        didSet {
            setSelectedState(isHighlighted)
        }
    }

    func setSelectedState(_ selected: Bool) {
        networkImage.alpha = selected ? 0.6 : 1.0
    }

    func populateFrom(_ network: PodcastNetwork) {
        if let title = network.title {
            networkImage.accessibilityLabel = L10n.discoverPodcastNetwork(title)
        }

        if let imageUrl = network.imageUrl {
            ImageManager.sharedManager.loadNetworkImage(imageUrl: imageUrl, imageView: networkImage)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        networkImage.image = ImageManager.sharedManager.placeHolderImage(.grid)
        shadowView.layer.shadowPath = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        networkImage?.layer.cornerRadius = bounds.height / 2
        shadowView?.layer.cornerRadius = bounds.height / 2
    }
}
