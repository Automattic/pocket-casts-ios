import PocketCastsDataModel
import UIKit

class SiriShortcutAddCell: ThemeableCell {
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var addIcon: TintableImageView! {
        didSet {
            addIcon.tintColor = ThemeColor.primaryInteractive01()
        }
    }

    func populateFrom(podcast: Podcast) {
        if let title = podcast.title {
            titleLabel.text = title
        }
        podcastImage.setPodcast(uuid: podcast.uuid, size: .grid)

        podcastImage.isHidden = false
        iconView.isHidden = true
    }

    func populateFrom(filter: EpisodeFilter) {
        titleLabel.text = filter.playlistName
        iconView.image = filter.iconImage()
        iconView.tintColor = filter.playlistColor()
        podcastImage.isHidden = true
        iconView.isHidden = false
    }
}
