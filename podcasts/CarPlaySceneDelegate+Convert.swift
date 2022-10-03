import CarPlay
import Foundation
import PocketCastsDataModel

extension CarPlaySceneDelegate {
    func convertToListItems(episodes: [BaseEpisode], showArtwork: Bool, closeListOnTap: Bool) -> [CPListItem] {
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

            if episode.episodeStatus != DownloadStatus.downloaded.rawValue {
                item.accessoryType = .cloud
            }

            item.isPlaying = PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid)

            item.handler = { [weak self] _, completion in
                self?.episodeTapped(episode, closeListOnTap: closeListOnTap)
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
            self?.podcastTapped(podcast, closeListOnTap: false)
            completion()
        }

        return item
    }

    func createUpNextImageItem(episodes: [BaseEpisode]) -> CPListImageRowItem {
        var images = [UIImage]()
        for episode in episodes {
            images.append(CarPlayImageHelper.imageForEpisode(episode))
        }

        let item = CPListImageRowItem(text: L10n.carplayUpNextQueue, images: images)
        item.listImageRowHandler = { [weak self] _, index, completion in
            guard let episode = episodes[safe: index] else { return }

            self?.episodeTapped(episode, closeListOnTap: false)
            completion()
        }

        item.handler = { [weak self] _, completion in
            guard let self = self else { return }

            let upNext = self.createUpNextList(includeNowPlaying: true)
            self.interfaceController?.pushTemplate(upNext, animated: true, completion: nil)
            completion()
        }

        return item
    }
}
