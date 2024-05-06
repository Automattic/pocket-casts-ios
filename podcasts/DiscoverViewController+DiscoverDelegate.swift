import Foundation
import PocketCastsDataModel
import PocketCastsServer

extension DiscoverViewController: DiscoverDelegate {
    func showExpanded(item: PocketCastsServer.DiscoverItem, category: PocketCastsServer.DiscoverCategory?) {
        if let category {
            reload(except: [item], category: category)
        } else {
            reloadDiscoverTapped(NSObject())
        }
    }

    func show(podcastInfo: PodcastInfo, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {
        let podcastController = PodcastViewController(podcastInfo: podcastInfo, existingImage: placeholderImage)
        podcastController.featuredPodcast = isFeatured
        podcastController.listUuid = listUuid

        navigationController?.pushViewController(podcastController, animated: true)
    }

    func show(discoverPodcast: DiscoverPodcast, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {
        var podcastInfo = PodcastInfo()
        podcastInfo.populateFrom(discoverPodcast: discoverPodcast)
        show(podcastInfo: podcastInfo, placeholderImage: placeholderImage, isFeatured: isFeatured, listUuid: listUuid)
    }

    func show(podcast: Podcast) {
        let podcastController = PodcastViewController(podcast: podcast)
        navigationController?.pushViewController(podcastController, animated: true)
    }

    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?) {
        if let listId = item.uuid {
            AnalyticsHelper.listShowAllTapped(listId: listId)
        } else {
            Analytics.track(.discoverShowAllTapped, properties: ["list_id": item.inferredListId])
        }

        if item.expandedStyle == "descriptive_list" || item.expandedStyle == "grid" {
            let collectionListVC = ExpandedCollectionViewController(item: item, podcasts: podcasts)
            collectionListVC.podcastCollection = podcastCollection
            collectionListVC.registerDiscoverDelegate(self)
            collectionListVC.cellStyle = (item.expandedStyle == "descriptive_list") ? CollectionCellStyle.descriptive_list : CollectionCellStyle.grid
            navController()?.pushViewController(collectionListVC, animated: true)
        } else { // item == expandedStylw == "plain_list" || item.expandedStyle == "ranked_list"
            let listView = PodcastHeaderListViewController(podcasts: podcasts)
            listView.title = replaceRegionName(string: item.title?.localized ?? "")
            listView.showFeaturedCell = item.expandedStyle == "ranked_list"
            listView.showRankingNumber = item.expandedStyle == "ranked_list"
            listView.registerDiscoverDelegate(self)
            navController()?.pushViewController(listView, animated: true)
        }
    }

    func showExpanded(item: DiscoverItem, episodes: [DiscoverEpisode], podcastCollection: PodcastCollection?) {
        guard let podcastCollection = podcastCollection else { return }

        if let listId = item.uuid {
            AnalyticsHelper.listShowAllTapped(listId: listId)
        }

        let listView = ExpandedEpisodeListViewController(podcastCollection: podcastCollection)
        listView.delegate = self
        navController()?.pushViewController(listView, animated: true)
    }

    func navController() -> UINavigationController? {
        navigationController
    }

    func replaceRegionCode(string: String?) -> String? {
        guard let fullString = string, let layout = discoverLayout else { return string }

        let currentRegionCode = Settings.discoverRegion(discoverLayout: layout)
        guard let serverRegion = layout.regions?[currentRegionCode] else { return fullString }

        return fullString.replacingOccurrences(of: layout.regionCodeToken, with: serverRegion.code)
    }

    func replaceRegionName(string: String) -> String {
        guard let layout = discoverLayout else { return string }

        let currentRegionCode = Settings.discoverRegion(discoverLayout: layout)
        guard let serverRegion = layout.regions?[currentRegionCode] else { return string }

        if let localizedRegion = string.localized(with: serverRegion.name.localized) {
            return localizedRegion
        }

        return string.replacingOccurrences(of: layout.regionNameToken, with: serverRegion.name)
    }

    func isSubscribed(podcast: DiscoverPodcast) -> Bool {
        if let uuid = podcast.uuid {
            if let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
                return true
            }
        }
        return false
    }

    func subscribe(podcast: DiscoverPodcast) {
        if podcast.iTunesOnly() {
            ServerPodcastManager.shared.addFromiTunesId(Int(podcast.iTunesId!)!, subscribe: true, completion: nil)
        } else if let uuid = podcast.uuid {
            ServerPodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: true, completion: nil)
        }

        HapticsHelper.triggerSubscribedHaptic()

        let uuid = podcast.uuid ?? podcast.iTunesId ?? "unknown"
        Analytics.track(.podcastSubscribed, properties: ["source": analyticsSource, "uuid": uuid])
    }

    func show(discoverEpisode: DiscoverEpisode, podcast: Podcast) {
        guard let uuid = discoverEpisode.uuid else { return }
        let episodeController = EpisodeDetailViewController(episodeUuid: uuid, podcast: podcast, source: .discover)
        episodeController.modalPresentationStyle = .formSheet
        present(episodeController, animated: true)
    }

    func failedToLoadEpisode() {
        SJUIUtils.showAlert(title: L10n.error, message: L10n.discoverFeaturedEpisodeErrorNotFound, from: self)
    }
}
