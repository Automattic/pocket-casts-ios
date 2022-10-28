import PocketCastsDataModel
import UIKit

class PodcastDisclosureCell: ThemeableCell {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var podcastName: ThemeableLabel!

    @IBOutlet var secondaryLabel: ThemeableLabel! {
        didSet {
            secondaryLabel.style = .primaryText02
        }
    }

    @IBOutlet var disclosureIndicator: UIImageView!

    override func handleThemeDidChange() {
        disclosureIndicator.tintColor = ThemeColor.primaryIcon02()
    }

    func populate(from podcast: Podcast, secondaryText: String) {
        podcastName.text = podcast.title
        podcastImage.setPodcast(uuid: podcast.uuid, size: .list)
        secondaryLabel.text = secondaryText
    }
}
