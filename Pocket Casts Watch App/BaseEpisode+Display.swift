import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

extension BaseEpisode {
    var largeImageUrl: URL {
        WatchImageHelper.largeImageUrl(episode: self)
    }

    var smallImageUrl: URL {
        if let userEpisode = self as? UserEpisode {
            return userEpisode.urlForImage(size: 280)
        }

        return ServerHelper.imageUrl(podcastUuid: parentIdentifier(), size: 130)
    }

    var subTitleColor: Color {
        guard let episode = self as? Episode, let podcast = episode.parentPodcast() else {
            return .white
        }

        return Color(ColorManager.darkThemeTintForPodcast(podcast))
    }

    var displayDate: String {
        EpisodeDateHelper.displayDate(forEpisode: self)
    }

    var episodeDetails: String {
        guard let episode = self as? Episode else {
            return L10n.customEpisode
        }

        return episode.episodeDescription ?? ""
    }
}
