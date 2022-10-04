
import UIKit

class PodcastSupporterCell: ThemeableCell {
    @IBOutlet var podcastArtwork: BundleImageView! {
        didSet {
            podcastArtwork.layer.cornerRadius = 4
        }
    }

    @IBOutlet var heartView: BundleHeartCountView!
    @IBOutlet var podcastName: ThemeableLabel!
    @IBOutlet var authorLabel: ThemeableLabel! {
        didSet {
            authorLabel.style = .primaryText02
        }
    }

    @IBOutlet var cancelledLabel: ThemeableLabel! {
        didSet {
            cancelledLabel.style = .support05
        }
    }

    @IBOutlet var frequencyLabel: ThemeableLabel! {
        didSet {
            frequencyLabel.style = .primaryText02
        }
    }

    @IBOutlet var dotLabel: ThemeableLabel! {
        didSet {
            dotLabel.style = .primaryText02
        }
    }

    @IBOutlet var bundleLabel: ThemeableLabel!
    @IBOutlet var loadingIndicator: ThemeLoadingIndicator!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryView = TintableImageView(image: UIImage(named: "chevron"))
        updateColor()
    }

    var isLoading = false {
        didSet {
            loadingIndicator.isHidden = !isLoading
            podcastName.isHidden = isLoading
            authorLabel.isHidden = isLoading
            cancelledLabel.isHidden = isLoading
            heartView.isHidden = isLoading
            if isLoading {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        }
    }
}
