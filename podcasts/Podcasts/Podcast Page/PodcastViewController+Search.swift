import Foundation
import PocketCastsServer

extension PodcastViewController {
    func setupSearchController() {
        let controller = EpisodeListSearchController()
        controller.placeholder = L10n.searchEpisodes
        controller.searchDebounce = Settings.episodeSearchDebounceTime()
        controller.delegate = self

        addChild(controller)
        controller.didMove(toParent: self)
        searchController = controller

        updateSearchHeader()
    }

    /// Updates the episode count and the archived button of the search header
    func updateSearchHeader() {
        guard let searchController, let podcast else { return }

        let hasEpisodeLimit = (podcast.autoArchiveEpisodeLimit > 0 && podcast.overrideGlobalArchive)
        let count = episodeCount()

        let infoText = (count == 1 ? L10n.podcastEpisodeCountSingular : L10n.podcastEpisodeCountPluralFormat(count.localized())) + " • "
        let info = NSMutableAttributedString(string: infoText, attributes: [.foregroundColor: AppTheme.colorForStyle(.primaryText02)])
        if hasEpisodeLimit {
            info.append(NSAttributedString(string: L10n.podcastEpisodeLimitCountFormat(podcast.autoArchiveEpisodeLimit.localized()), attributes: [.foregroundColor: AppTheme.colorForStyle(.support08)]))
        } else {
            info.append(NSAttributedString(string: L10n.podcastArchivedCountFormat(archivedEpisodeCount().localized()), attributes: [.foregroundColor: AppTheme.colorForStyle(.primaryText02)]))
        }

        searchController.info = info
        searchController.actionTitle = showingArchived() ? L10n.podcastHideArchived : L10n.podcastShowArchived
    }

    func performEpisodeSearch(query: String) {
        guard let podcast else { return }

        let search = CacheServerHandler.EpisodeSearchQuery(podcastUuid: podcast.uuid, searchTerm: query)
        CacheServerHandler.shared.searchEpisodesInPodcast(search: search) { [weak self] results in
            self?.showSearchResults(results)
        }
    }

    func showSearchResults(_ result: CacheServerHandler.EpisodeSearchResult?) {
        DispatchQueue.main.async { [weak self] in
            self?.searchController?.isLoading = false
        }

        guard let podcast, let result else { return }

        uuidsThatMatchSearch.removeAll()

        for episode in result.episodes {
            uuidsThatMatchSearch.append(episode.uuid)
        }

        loadLocalEpisodes(podcast: podcast, animated: true)
    }
}

// MARK: - EpisodeListSearchControllerDelegate

extension PodcastViewController: EpisodeListSearchControllerDelegate {
    func episodeListSearchController(_ controller: EpisodeListSearchController, didChangeSearchTerm searchTerm: String) {
        searchEpisodes(query: searchTerm)
    }

    func episodeListSearchController(_ controller: EpisodeListSearchController, didSubmitSearchTerm searchTerm: String) {
        searchEpisodes(query: searchTerm)
    }

    func episodeListSearchControllerDidBeginEditing(_ controller: EpisodeListSearchController) {
        didActivateSearch()
    }

    func episodeListSearchControllerDidTapAction(_ controller: EpisodeListSearchController) {
        toggleShowArchived()
    }

    func episodeListSearchControllerDidTapOverflow(_ controller: EpisodeListSearchController) {
        showEpisodeOptions()
    }
}
