import PocketCastsServer
import UIKit

class FeaturedCollectionViewCell: UICollectionViewCell {
    @IBOutlet var featuredView: DiscoverFeaturedView!

    func populateFrom(_ discoverPodcast: DiscoverPodcast, isSubscribed: Bool, listName: String, isSponsored: Bool) {
        featuredView.populateFrom(discoverPodcast, isSubscribed: isSubscribed, listName: listName, isSponsored: isSponsored)
    }

    func setPodcastColor(_ color: UIColor) {
        featuredView.setPodcastColor(color)
    }

    override var isHighlighted: Bool {
        didSet {
            featuredView.setSelectedState(isHighlighted)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        featuredView.clearView()
    }
}
