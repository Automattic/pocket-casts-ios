import PocketCastsServer
import UIKit

class FeaturedTableViewCell: UITableViewCell {
    @IBOutlet var featuredView: DiscoverFeaturedView!

    func populateFrom(_ discoverPodcast: DiscoverPodcast, isSubscribed: Bool, listName: String) {
        featuredView.populateFrom(discoverPodcast, isSubscribed: isSubscribed, listName: listName)
    }

    func populateFrom(_ discoverPodcast: DiscoverPodcast, listName: String) {
        featuredView.populateFrom(discoverPodcast, listName: listName)
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

    func showRanking() {
        featuredView.showRanking()
    }
}
