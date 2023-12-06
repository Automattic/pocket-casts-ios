import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension PodcastViewController {
    func loadPodcastInfoFromiTunesId(_ iTunesId: Int) {
        loadingStarted()
        ServerPodcastManager.shared.addFromiTunesId(iTunesId, subscribe: false) { [weak self] added, uuid in
            guard let strongSelf = self else { return }

            strongSelf.processPodcastAdded(added: added, uuid: uuid)
        }
    }

    func loadPodcastInfoFromUuid(_ uuid: String) {
        loadingStarted()
        ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: false) { [weak self] added in
            guard let strongSelf = self else { return }

            strongSelf.processPodcastAdded(added: added, uuid: uuid)
        }
    }

    func checkIfPodcastNeedsUpdating() {
        guard let podcast = podcast else { return }
        ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast, addMissingEpisodes: true) { [weak self] updated in
            if updated {
                self?.loadLocalEpisodes(podcast: podcast, animated: true)
            }
        }
    }

    private func processPodcastAdded(added: Bool, uuid: String?) {
        guard let uuid = uuid, let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) else {
            loadingEnded(successfully: false)

            return
        }

        self.podcast = podcast
        summaryExpanded = !podcast.isSubscribed()

        if SyncManager.isUserLoggedIn() {
            guard let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: uuid) else { return }

            DataManager.sharedManager.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
        }
        loadLocalEpisodes(podcast: podcast, animated: false)

        loadingEnded(successfully: true)
    }

    func loadingStarted() {
        if loadingPodcastInfo { return }

        loadingPodcastInfo = true
        DispatchQueue.main.async {
            self.episodesTable.alpha = 0
            self.loadingIndicator.startAnimating()
        }
    }

    func loadingEnded(successfully: Bool) {
        if !loadingPodcastInfo { return }

        loadingPodcastInfo = false
        DispatchQueue.main.async {
            if !successfully {
                SJUIUtils.showAlert(title: L10n.podcastErrorTitle, message: L10n.podcastErrorMessage, from: self, completion: {
                    // we need to move this pop to the end of the UI stack, because it complains about multiple transitions otherwise
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                })

                return
            }

            self.loadingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.5) {
                self.episodesTable.alpha = 1
            }
        }
    }
}
