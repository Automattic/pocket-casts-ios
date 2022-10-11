import CarPlay
import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension CarPlaySceneDelegate {
    func filterTapped(_ filter: EpisodeFilter) {
        pushEpisodeList(title: filter.playlistName, showArtwork: true, closeListOnTap: false) { () -> [BaseEpisode] in
            let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Constants.Limits.maxCarplayItems)
            return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
        }
    }

    func podcastTapped(_ podcast: Podcast, closeListOnTap: Bool) {
        pushEpisodeList(title: podcast.title ?? L10n.podcastSingular, showArtwork: false, closeListOnTap: closeListOnTap) { () -> [BaseEpisode] in
            var query = PodcastEpisodesRefreshOperation(podcast: podcast, uuidsToFilter: nil, completion: nil).createEpisodesQuery()
            query += " LIMIT \(Constants.Limits.maxCarplayItems)"

            return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
        }
    }

    func folderTapped(_ folder: Folder, closeListOnTap: Bool) {
        pushPodcastList(title: folder.name, closeListOnTap: closeListOnTap) {
            DataManager.sharedManager.allPodcastsInFolder(folder: folder)
        }

        if closeListOnTap {
            interfaceController?.popTemplateIgnoringException()
        }
    }

    func episodeTapped(_ episode: BaseEpisode, closeListOnTap: Bool) {
        AnalyticsPlaybackHelper.shared.currentSource = .carPlay

        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            PlaybackManager.shared.playPause()
        } else {
            PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
        }

        if closeListOnTap {
            interfaceController?.popTemplateIgnoringException()
        }
    }

    func listeningHistoryTapped() {
        pushEpisodeList(title: L10n.listeningHistory, showArtwork: true, closeListOnTap: false) { () -> [BaseEpisode] in
            let query = "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT \(Constants.Limits.maxCarplayItems)"
            return DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
        }
    }

    func filesTapped(closeListOnTap: Bool) {
        pushEpisodeList(title: L10n.files, showArtwork: true, closeListOnTap: closeListOnTap) { () -> [BaseEpisode] in
            let sortBy = UploadedSort(rawValue: Settings.userEpisodeSortBy()) ?? UploadedSort.newestToOldest
            return DataManager.sharedManager.allUserEpisodes(sortedBy: sortBy)
        }
    }

    func chaptersTapped() {
        AnalyticsPlaybackHelper.shared.currentSource = .carPlay

        let chapterCount = PlaybackManager.shared.chapterCount()
        guard chapterCount > 0 else { return }

        var chapterItems = [CPListItem]()
        let currentChapter = PlaybackManager.shared.currentChapter()
        for i in 0 ... chapterCount {
            guard let chapter = PlaybackManager.shared.chapterAt(index: i) else { continue }

            let chapterLength = TimeFormatter.shared.singleUnitFormattedShortestTime(time: chapter.duration)
            let subtTitle = L10n.carplayChapterCount((i + 1).localized(), chapterCount.localized(), chapterLength)
            let chapterItem = CPListItem(text: chapter.title, detailText: subtTitle)
            chapterItem.isPlaying = currentChapter?.index == chapter.index
            chapterItem.playingIndicatorLocation = .trailing
            chapterItem.handler = { [weak self] _, completion in
                PlaybackManager.shared.skipToChapter(chapter)
                self?.interfaceController?.popTemplateIgnoringException()
                completion()
            }

            chapterItems.append(chapterItem)
        }

        let mainSection = CPListSection(items: chapterItems)
        let listTemplate = CPListTemplate(title: L10n.chapters, sections: [mainSection])

        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }

    func speedTapped() {
        let currentSpeed = PlaybackManager.shared.effects().playbackSpeed

        var speedItems = [CPListItem]()
        addSpeed(0.5, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(1.0, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(1.2, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(1.4, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(1.6, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(1.8, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(2.0, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(2.2, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(2.4, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(2.6, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(2.8, to: &speedItems, currentSpeed: currentSpeed)
        addSpeed(3.0, to: &speedItems, currentSpeed: currentSpeed)

        let mainSection = CPListSection(items: speedItems)
        let listTemplate = CPListTemplate(title: L10n.carplayPlaybackSpeed, sections: [mainSection])

        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }

    private func addSpeed(_ speed: Double, to itemList: inout [CPListItem], currentSpeed: Double) {
        let item = CPListItem(text: L10n.playbackSpeed(speed.localized()), detailText: nil)
        item.playingIndicatorLocation = .trailing
        item.isPlaying = (speed == currentSpeed)
        item.handler = { [weak self] _, completion in
            let effects = PlaybackManager.shared.effects()
            effects.playbackSpeed = speed
            PlaybackManager.shared.changeEffects(effects)

            self?.interfaceController?.popTemplateIgnoringException()
            completion()
        }

        itemList.append(item)
    }

    private func pushEpisodeList(title: String, showArtwork: Bool, closeListOnTap: Bool, episodeLoader: @escaping (() -> [BaseEpisode])) {
        let episodes = episodeLoader()
        let episodeItems = convertToListItems(episodes: episodes, showArtwork: showArtwork, closeListOnTap: closeListOnTap)

        let mainSection = CPListSection(items: episodeItems)
        let listTemplate = CPListTemplate(title: title, sections: [mainSection])

        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
        currentList = CarPlayListHelper(list: listTemplate, episodeLoader: episodeLoader, showsArtwork: showArtwork, closeListOnTap: closeListOnTap)
    }

    private func pushPodcastList(title: String, closeListOnTap: Bool, podcastLoader: @escaping (() -> [Podcast])) {
        let podcasts = podcastLoader()
        var podcastItems = [CPListItem]()
        for podcast in podcasts {
            let item = convertPodcastToListItem(podcast)
            podcastItems.append(item)
        }

        let mainSection = CPListSection(items: podcastItems)
        let listTemplate = CPListTemplate(title: title, sections: [mainSection])

        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
        currentList = nil
    }
}

extension CPInterfaceController {
    // popTemplate will throw an exception if no completion handler is present and a template can't be popped, so to work around that we have this method which captures the error and prints it since we don't particularly care
    func popTemplateIgnoringException() {
        popTemplate(animated: true) { _, error in
            if let error = error {
                print(error)
            }
        }
    }
}
