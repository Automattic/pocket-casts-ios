import PocketCastsServer
import PocketCastsDataModel

extension DiscoverCollectionViewController: DiscoverDelegate {
    func navigateTo(category: String) {
        if isViewLoaded {
            NotificationCenter.default.post(name: Constants.Notifications.discoverNavigateToCategory, object: category)
        } else {
            loadViewIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5.seconds) {
                NotificationCenter.default.post(name: Constants.Notifications.discoverNavigateToCategory, object: category)
            }
        }
    }

    func navigateTo(listID: String) {
        if isViewLoaded {
            showItemWith(identifier: listID)
        } else {
            loadViewIfNeeded()
            reloadData { [weak self] in
                self?.showItemWith(identifier: listID)
            }
        }
    }

    func invalidate(item: PocketCastsServer.DiscoverItem) {
        let context = UICollectionViewLayoutInvalidationContext()
        let item = dataSource.snapshot().itemIdentifiers.first(where: {
            if case .item(let item) = $0 {
                item == item
            } else {
                false
            }
        })
        guard let item,
              let indexPath = dataSource?.indexPath(for: item) else {
            return
        }
        context.invalidateItems(at: [indexPath])
        collectionView.collectionViewLayout.invalidateLayout(with: context)
    }

    func showExpanded(item: PocketCastsServer.DiscoverItem, category: PocketCastsServer.DiscoverCategory?) {
        if let category {
            if let categoryId = category.id, let categoryName = category.name, let discoverLayout {
                let currentRegion = Settings.discoverRegion(discoverLayout: discoverLayout)
                Analytics.track(.discoverCategoryShown, properties: ["name": categoryName, "region": currentRegion, "id": categoryId])
            }
            reload(except: [item], category: category)
        } else {
            reload(except: [item], category: nil)
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

    func showItemWith(identifier: String) {
        guard let items = discoverLayout?.layout,
              let item = items.first(where: { $0.id == identifier || $0.uuid == identifier})
        else {
            return
        }

        guard let source = item.source else { return }

        DiscoverServerHandler.shared.discoverPodcastList(source: source, authenticated: item.authenticated, completion: { [weak self] podcastList in
            guard let self, let discoverPodcast = podcastList?.podcasts else { return }

            let podcasts: [DiscoverPodcast]
            if let itemCount = item.summaryItemCount {
                podcasts = Array(discoverPodcast[0..<itemCount])
            } else {
                podcasts = discoverPodcast
            }

            DispatchQueue.main.async {
                self.showExpanded(item: item, podcasts: podcasts, podcastCollection: nil)
            }
        })
    }

    func showExpanded(item: PocketCastsServer.DiscoverItem, podcasts: [PocketCastsServer.DiscoverPodcast], podcastCollection: PocketCastsServer.PodcastCollection?) {
        showExpanded(item: item, podcasts: podcasts, podcastCollection: podcastCollection, datetime: nil)
    }

    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?, datetime: String? = nil) {
        if let listId = item.uuid {
            AnalyticsHelper.listShowAllTapped(listId: listId, dateTime: datetime)
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
            let source = replaceRegionCode(string: item.source ?? "")
            let listView = PodcastHeaderListViewController(podcasts: podcasts, source: source, isAuthenticated: item.isAuthenticated)
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
            AnalyticsHelper.listShowAllTapped(listId: listId, dateTime: podcastCollection.datetime)
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
            ServerPodcastManager.shared.subscribeFromItunesId(Int(podcast.iTunesId!)!, completion: nil)
        } else if let uuid = podcast.uuid {
            ServerPodcastManager.shared.subscribe(to: uuid, completion: nil)
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
