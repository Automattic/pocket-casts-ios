import CarPlay
import Foundation
import PocketCastsDataModel
import PocketCastsServer
import UIKit

class CarPlaySceneDelegate: CustomObserver, CPTemplateApplicationSceneDelegate, CPNowPlayingTemplateObserver {
    var interfaceController: CPInterfaceController?

    // Reloading
    var debouncer: Debounce = .init(delay: 0.2)
    weak var visibleTemplate: CPTemplate?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        interfaceController.delegate = self

        let tabTemplate = CPTabBarTemplate(templates: [createPodcastsTab(), createFiltersTab(), createDownloadsTab(), createMoreTab()])
        interfaceController.setRootTemplate(tabTemplate)

        self.visibleTemplate = tabTemplate.selectedTemplate

        setupNowPlaying()
        addChangeListeners()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        removeAllCustomObservers()
        self.interfaceController?.delegate = nil
        self.interfaceController = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appDelegate()?.handleBecomeActive()
    }

    private func addChangeListeners() {
        let notifications = [
            // Podcast Changes
            ServerNotifications.podcastsRefreshed,
            Constants.Notifications.opmlImportCompleted,

            // Filters
            Constants.Notifications.filterChanged,

            // Episode changes
            Constants.Notifications.episodeDownloaded,
            Constants.Notifications.episodePlayStatusChanged,
            Constants.Notifications.episodeArchiveStatusChanged,
            Constants.Notifications.episodeDurationChanged,
            Constants.Notifications.episodeDownloadStatusChanged,
            ServerNotifications.episodeTypeOrLengthChanged,
            Constants.Notifications.manyEpisodesChanged,

            // Up Next Changes
            Constants.Notifications.upNextQueueChanged,
            Constants.Notifications.upNextEpisodeAdded,
            Constants.Notifications.upNextEpisodeRemoved,

            // User Episodes
            Constants.Notifications.userEpisodeUpdated,
            Constants.Notifications.userEpisodeDeleted,
            ServerNotifications.userEpisodesRefreshed,
        ]

        for notification in notifications {
            addCustomObserver(notification, selector: #selector(handleDataUpdated))
        }

        let playbackNotifications = [
            Constants.Notifications.playbackTrackChanged,
            Constants.Notifications.playbackEnded,
            Constants.Notifications.podcastChaptersDidUpdate,
            Constants.Notifications.playbackStarted
        ]

        for notification in playbackNotifications {
            addCustomObserver(notification, selector: #selector(handlePlaybackStateChanged))
        }
    }

    @objc private func handlePlaybackStateChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let nowPlayingTemplate = CPNowPlayingTemplate.shared
            self.updateNowPlayingButtons(template: nowPlayingTemplate)

            // Also update the episode list if needed, this makes sure its updated when the episode ends
            self.handleDataUpdated()
        }
    }

    @objc private func handleDataUpdated() {
        // Prevent updating too often when multiple notifications fire at once
        debouncer.call {
            self.reloadVisibleTemplate()
        }
    }

    func reloadVisibleTemplate() {
        visibleTemplate?.reloadData()
    }

    private func setupNowPlaying() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.isUpNextButtonEnabled = true
        nowPlayingTemplate.isAlbumArtistButtonEnabled = true
        nowPlayingTemplate.add(self)

        updateNowPlayingButtons(template: nowPlayingTemplate)
    }

    private func updateNowPlayingButtons(template: CPNowPlayingTemplate) {
        var buttons = [CPNowPlayingButton]()

        if let image = UIImage(named: "car_markasplayed") {
            let markPlayedBtn = CPNowPlayingImageButton(image: image) { _ in
                guard let episode = PlaybackManager.shared.currentEpisode() else { return }
                AnalyticsEpisodeHelper.shared.currentSource = .carPlay

                EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
            }
            buttons.append(markPlayedBtn)
        }

        let rateButton = CPNowPlayingPlaybackRateButton { [weak self] _ in
            self?.speedTapped()
        }

        buttons.append(rateButton)

        // show the chapter picker if there are chapters
        if PlaybackManager.shared.chapterCount() > 0, let chapterImage = UIImage(named: "car_chapters") {
            let chapterButton = CPNowPlayingImageButton(image: chapterImage) { [weak self] _ in
                self?.chaptersTapped()
            }

            buttons.append(chapterButton)
        }

        template.updateNowPlayingButtons(buttons)
    }

    // MARK: - CPNowPlayingTemplateObserver

    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        upNextTapped(showNowPlaying: false)
    }

    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        if let episode = playingEpisode as? Episode, let podcast = episode.parentPodcast() {
            podcastTapped(podcast)
        } else if playingEpisode is UserEpisode {
            filesTapped()
        }
    }
}

// MARK: - CPInterfaceControllerDelegate
extension CarPlaySceneDelegate: CPInterfaceControllerDelegate {
    func templateDidAppear(_ template: CPTemplate, animated: Bool) {
        // We ignore the tab template because we only want to get the selected tab template
        // This will be called for both the tab template, and the selected tab
        guard (template as? CPTabBarTemplate) == nil, visibleTemplate != template else {
            return
        }

        visibleTemplate = template
        template.didAppear()
    }

    func templateDidDisappear(_ template: CPTemplate, animated: Bool) {
        template.didDisappear()
    }
}
