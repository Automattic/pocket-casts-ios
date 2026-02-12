import PocketCastsDataModel
import UIKit

class SiriShortcutAddCell: ThemeableCell {
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.font(ofSize: 16.0, weight: .medium, scalingWith: .callout)
        }
    }

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
        updateSize()
    }

    func populateFrom(filter: EpisodeFilter) {
        titleLabel.text = filter.playlistName
        iconView.image = filter.iconImage()
        iconView.tintColor = filter.playlistColor()
        podcastImage.isHidden = true
        iconView.isHidden = false
        updateSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    private func updateSize() {
        let iconMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let iconSize = max(24, iconMetric.scaledValue(for: 24))
        addIcon.updateSizeConstraints(to: iconSize)

        let imageSize = max(44, iconMetric.scaledValue(for: 44))
        podcastImage.updateSizeConstraints(to: imageSize)

        let filterImageSize = max(32, iconMetric.scaledValue(for: 32))
        iconView.updateSizeConstraints(to: filterImageSize)
    }
}
