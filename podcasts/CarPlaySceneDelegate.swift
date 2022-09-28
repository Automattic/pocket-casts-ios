import CarPlay
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class CarPlaySceneDelegate: CustomObserver, CPTemplateApplicationSceneDelegate, CPNowPlayingTemplateObserver {
    var interfaceController: CPInterfaceController?

    var currentList: CarPlayListHelper?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController

        let tabTemplate = CPTabBarTemplate(templates: [createPodcastsTab(), createFiltersTab(), createDownloadsTab(), createMoreTab()])
        interfaceController.setRootTemplate(tabTemplate, animated: true, completion: nil)

        setupNowPlaying()
        addChangeListeners()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        removeAllCustomObservers()

        self.interfaceController = nil
        currentList = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appDelegate()?.handleBecomeActive()
    }

    private func addChangeListeners() {
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.opmlImportCompleted, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.filterChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.episodeDurationChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(ServerNotifications.episodeTypeOrLengthChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.upNextQueueChanged, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.upNextEpisodeAdded, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.upNextEpisodeRemoved, selector: #selector(handleDataUpdated))

        // playback related
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(handlePlaybackStateChanged))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(handlePlaybackStateChanged))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(handlePlaybackStateChanged))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(handlePlaybackStateChanged))

        // user episode notifications
        addCustomObserver(Constants.Notifications.userEpisodeUpdated, selector: #selector(handleDataUpdated))
        addCustomObserver(Constants.Notifications.userEpisodeDeleted, selector: #selector(handleDataUpdated))
        addCustomObserver(ServerNotifications.userEpisodesRefreshed, selector: #selector(handleDataUpdated))
    }

    @objc private func handlePlaybackStateChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let nowPlayingTemplate = CPNowPlayingTemplate.shared
            self.updateNowPlayingButtons(template: nowPlayingTemplate)
        }
    }

    @objc private func handleDataUpdated() {
        guard let currentList = currentList else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let reloadedEpisodes = currentList.episodeLoader()
            let episodeItems = self.convertToListItems(episodes: reloadedEpisodes, showArtwork: currentList.showsArtwork, closeListOnTap: currentList.closeListOnTap)
            let mainSection = CPListSection(items: episodeItems)

            currentList.list.updateSections([mainSection])
        }
    }

    private func setupNowPlaying() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.isUpNextButtonEnabled = true
        nowPlayingTemplate.isAlbumArtistButtonEnabled = true
        nowPlayingTemplate.add(self)

        updateNowPlayingButtons(template: nowPlayingTemplate)
    }

    private func updateNowPlayingButtons(template: CPNowPlayingTemplate) {
        guard let markPlayedImage = themeTintedImage(named: "car_markasplayed") else { return }

        var buttons = [CPNowPlayingButton]()

        let markPlayedBtn = CPNowPlayingImageButton(image: markPlayedImage) { _ in
            guard let episode = PlaybackManager.shared.currentEpisode() else { return }

            EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        }
        buttons.append(markPlayedBtn)

        let rateButton = CPNowPlayingPlaybackRateButton { [weak self] _ in
            self?.speedTapped()
        }
        buttons.append(rateButton)

        // show the chapter picker if there are chapters
        if PlaybackManager.shared.chapterCount() > 0, let chapterImage = themeTintedImage(named: "car_chapters") {
            let chapterButton = CPNowPlayingImageButton(image: chapterImage) { [weak self] _ in
                self?.chaptersTapped()
            }

            buttons.append(chapterButton)
        }

        template.updateNowPlayingButtons(buttons)
    }

    func createUpNextList(includeNowPlaying: Bool) -> CPListTemplate {
        let episodes = PlaybackManager.shared.queue.allEpisodes(includeNowPlaying: includeNowPlaying)
        let upNextEpisodes = convertToListItems(episodes: episodes, showArtwork: true, closeListOnTap: true)

        let upNextSection = CPListSection(items: upNextEpisodes)
        let template = CPListTemplate(title: L10n.upNext, sections: [upNextSection])

        return template
    }

    // MARK: - CPNowPlayingTemplateObserver

    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        let upNextList = createUpNextList(includeNowPlaying: false)
        interfaceController?.pushTemplate(upNextList, animated: true, completion: nil)
    }

    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        if let episode = playingEpisode as? Episode, let podcast = episode.parentPodcast() {
            podcastTapped(podcast, closeListOnTap: true)
        } else if playingEpisode is UserEpisode {
            filesTapped(closeListOnTap: true)
        }
    }

    // while the documentation says you can do this at an Asset Catalog level by specifying different images, it doesn't appear to work for CarPlay (last tested in iOS 14.1)
    private func themeTintedImage(named imageName: String) -> UIImage? {
        // default to dark if no theme information is available since that's a more commone setup
        let isDarkTheme = interfaceController?.carTraitCollection.userInterfaceStyle != .light

        return UIImage(named: imageName)?.tintedImage(isDarkTheme ? UIColor.white : UIColor.black)
    }
}
