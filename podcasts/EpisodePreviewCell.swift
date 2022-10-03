import PocketCastsDataModel
import UIKit

class EpisodePreviewCell: ThemeableCell {
    @IBOutlet var episodeImage: PodcastImageView!
    @IBOutlet var episodeTitle: ThemeableLabel!

    @IBOutlet var durationLabel: ThemeableLabel! {
        didSet {
            durationLabel.style = .primaryText02
        }
    }

    @IBOutlet var dateLabel: ThemeableLabel! {
        didSet {
            dateLabel.style = .primaryText02
        }
    }

    func populateFrom(episode: BaseEpisode) {
        episodeTitle.text = episode.title
        if let userEpisode = episode as? UserEpisode {
            episodeImage.setUserEpisode(uuid: userEpisode.uuid, size: .list)
        } else {
            episodeImage.setPodcast(uuid: episode.parentIdentifier(), size: .list)
        }
        EpisodeDateHelper.setDate(episode: episode, on: dateLabel, tintColor: nil)
        durationLabel.text = episode.displayableTimeLeft()
    }
}
