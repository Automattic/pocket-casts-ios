import CarPlay
import Foundation
import PocketCastsDataModel
import CoreMedia

extension CarPlaySceneDelegate {
    func convertToListItems(episodes: [BaseEpisode], showArtwork: Bool, playlist: AutoplayHelper.Playlist?) -> [CPListItem] {
        var items = [CPListItem]()
        for episode in episodes {
            let artwork = showArtwork ? CarPlayImageHelper.imageForEpisode(episode) : nil
            let item = CPListItem(text: episode.displayableTitle(), detailText: episode.subTitle(), image: artwork)

            if episode.unplayed() {
                item.playbackProgress = 0
            } else if episode.played() {
                item.playbackProgress = 1.0
            } else {
                if episode.duration > 0 {
                    item.playbackProgress = CGFloat(min(1.0, episode.playedUpTo / episode.duration))
                } else {
                    item.playbackProgress = 0.5
                }
            }

            // On iOS 26.4 and later, CarPlay uses `playbackConfiguration` to display
            // elapsed time and duration, which lets it show playback progress correctly.
            if #available(iOS 26.4, *) {
                let duration = episode.duration
                var elapsedTime = min(episode.playedUpTo, episode.duration)
                if episode.unplayed() {
                    elapsedTime = 0
                } else if episode.played() {
                    elapsedTime = episode.duration
                }
                if duration > 0 {
                    item.playbackConfiguration = CPPlaybackConfiguration(preferredPresentation: .audio, playbackAction: .none, elapsedTime: CMTime(seconds: elapsedTime, preferredTimescale: .audio), duration: CMTime(seconds: duration, preferredTimescale: .audio))
                }
            }

            if episode.episodeStatus != DownloadStatus.downloaded.rawValue {
                item.accessoryType = .cloud
            }

            item.isPlaying = PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid)

            item.handler = { [weak self] _, completion in
                self?.episodeTapped(episode, playlist: playlist)
                completion()
            }

            items.append(item)
        }

        return items
    }

    func convertPodcastToListItem(_ podcast: Podcast) -> CPListItem {
        let item = CPListItem(text: podcast.title, detailText: nil, image: CarPlayImageHelper.imageForPodcast(podcast))

        item.accessoryType = .disclosureIndicator
        item.handler = { [weak self] _, completion in
            self?.podcastTapped(podcast)
            completion()
        }

        return item
    }

    func createUpNextImageItem(episodes: [BaseEpisode]) -> CPListImageRowItem {
        var images = [UIImage]()
        for episode in episodes {
            images.append(CarPlayImageHelper.imageForEpisode(episode, maxSize: CPListImageRowItem.maximumImageSize))
        }

        let item = CPListImageRowItem(text: L10n.carplayUpNextQueue, images: images)
        item.listImageRowHandler = { [weak self] _, index, completion in
            guard let episode = episodes[safe: index] else { return }

            self?.episodeTapped(episode)
            completion()
        }

        item.handler = { [weak self] _, completion in
            guard let self else { return }

            self.upNextTapped(showNowPlaying: true)
            completion()
        }

        return item
    }
}
