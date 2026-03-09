import PocketCastsDataModel
import UIKit

class EpisodePreviewCell: ThemeableCell {
    @IBOutlet var episodeImage: PodcastImageView!

    @IBOutlet var episodeTitle: ThemeableLabel! {
        didSet {
            episodeTitle.font = .font(ofSize: 15, weight: .medium, scalingWith: .subheadline)
        }
    }

    @IBOutlet var durationLabel: ThemeableLabel! {
        didSet {
            durationLabel.style = .primaryText02
            durationLabel.font = .font(ofSize: 11, weight: .semibold, scalingWith: .caption2)
        }
    }

    @IBOutlet var dateLabel: ThemeableLabel! {
        didSet {
            dateLabel.style = .primaryText02
            dateLabel.font = .font(ofSize: 12, weight: .semibold, scalingWith: .caption1)
        }
    }

    @IBOutlet weak var imageLeftPadding: NSLayoutConstraint!

    func populateFrom(episode: BaseEpisode) {
        episodeTitle.text = episode.title
        if let userEpisode = episode as? UserEpisode {
            episodeImage.setUserEpisode(uuid: userEpisode.uuid, size: .list)
        } else {
            episodeImage.setPodcast(uuid: episode.parentIdentifier(), size: .list)
        }
        EpisodeDateHelper.setDate(episode: episode, on: dateLabel, tintColor: nil)
        durationLabel.text = episode.displayableTimeLeft()

        updateSize()
    }

    // MARK: - Dynamic Type Updates

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let imageSize = max(56, metric.scaledValue(for: 56))

        episodeImage.updateSizeConstraints(to: imageSize)

        episodeTitle.updateNumberOfLines(regular: 2, accessibility: 3)
        dateLabel.updateNumberOfLines(regular: 2, accessibility: 3)
        durationLabel.updateNumberOfLines(regular: 1, accessibility: 3)
    }
}
