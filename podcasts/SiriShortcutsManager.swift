import Foundation
import Intents
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class SiriShortcutsManager: CustomObserver {
    static let shared = SiriShortcutsManager()

    var analyticsSource: AnalyticsSource {
        .siri
    }

    func setup() {
        addDefaultSuggestions()
        publishSubscribedPodcasts()
        addCustomObserver(Constants.Notifications.podcastAdded, selector: #selector(publishSubscribedPodcasts))
        addCustomObserver(Constants.Notifications.podcastDeleted, selector: #selector(publishSubscribedPodcasts))
    }

    func defaultSuggestions() -> [INShortcut] {
        var shortcuts = [resumeLastShortcut(), pauseShortcut(), playNextShortcut(), nextChapterShortcut(), previousChapterShortcut(), sleepTimerShortcut(), extendSleepTimerShortcut()]

        // only signed in users can use the play suggested shortcut
        if SyncManager.isUserLoggedIn() {
            shortcuts.insert(playSuggestedShortcut(), at: 2)
        }

        return shortcuts
    }

    func addDefaultSuggestions() {
        INVoiceShortcutCenter.shared.setShortcutSuggestions(defaultSuggestions())
    }

    func removeAllSuggestions() {
        INVoiceShortcutCenter.shared.setShortcutSuggestions([])
    }

    func isDefaultSuggestion(voiceShortcut: INVoiceShortcut) -> Bool {
        defaultSuggestions().contains { $0.intent?.suggestedInvocationPhrase == voiceShortcut.shortcut.intent?.suggestedInvocationPhrase }
    }

    func voiceShortcutForPodcast(podcast: Podcast, completion: @escaping ((INVoiceShortcut?) -> Void)) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { allVoiceShortcuts, _ in
            if let shortcuts = allVoiceShortcuts {
                for shortcut in shortcuts {
                    let intent = shortcut.shortcut.intent
                    guard intent is INPlayMediaIntent else { continue }
                    if let playMediaIntent = intent as? INPlayMediaIntent {
                        if playMediaIntent.mediaContainer?.identifier == podcast.uuid {
                            completion(shortcut)
                            return
                        }
                    }
                }
            }
            completion(nil)
        }
    }

    func voiceShortcutForFilter(filter: EpisodeFilter, completion: @escaping ((INVoiceShortcut?) -> Void)) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { allVoiceShortcuts, error in
            if let shortcuts = allVoiceShortcuts {
                for shortcut in shortcuts {
                    let intent = shortcut.shortcut.intent
                    guard intent is INPlayMediaIntent else { continue }
                    if let playMediaIntent = intent as? INPlayMediaIntent {
                        if playMediaIntent.mediaContainer?.identifier == filter.uuid {
                            completion(shortcut)
                            return
                        }
                    }
                }
            }
            if let error = error {
                FileLog.shared.addMessage("Failed INVoiceShortcutCenter.getAllVoiceShortcuts with error \(error.localizedDescription)")
            }
            completion(nil)
        }
    }

    // MARK: Shortcuts

    func resumeLastShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: resumeLastIntent())
        return shortcut!
    }

    func pauseShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: pauseIntent())
        return shortcut!
    }

    func playNextShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: playNextIntent())
        return shortcut!
    }

    func playSuggestedShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: playSuggestedIntent())
        return shortcut!
    }

    func playPodcastShortcut(podcast: Podcast) -> INShortcut {
        let shortcut = INShortcut(intent: playPodcastIntent(podcast: podcast))
        return shortcut!
    }

    func playFilterShortcut(filter: EpisodeFilter) -> INShortcut {
        let shortcut = INShortcut(intent: playFilterIntent(filter: filter))
        return shortcut!
    }

    func playAllFilterShortcut(filter: EpisodeFilter) -> INShortcut {
        let shortcut = INShortcut(intent: playAllFilterIntent(filter: filter))
        return shortcut!
    }

    func openFilterShortcut(filter: EpisodeFilter) -> INShortcut {
        let shortcut = INShortcut(intent: openFilterIntent(filter: filter))
        return shortcut!
    }

    func nextChapterShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: nextChapterIntent())
        return shortcut!
    }

    func previousChapterShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: previousChapterIntent())
        return shortcut!
    }

    func sleepTimerShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: setSleepTimerIntent())
        return shortcut!
    }

    func extendSleepTimerShortcut() -> INShortcut {
        let shortcut = INShortcut(intent: setExtendSleepTimerIntent())
        return shortcut!
    }

    // MARK: Intents

    func resumeLastIntent() -> INIntent {
        let artwork = INImage(named: "siri_play")
        let episode = INMediaItem(identifier: Constants.SiriActions.resumeId,
                                  title: L10n.siriShortcutResumeTitle,
                                  type: .podcastEpisode,
                                  artwork: artwork)

        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: nil, playShuffled: false, playbackRepeatMode: .one, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutResumePhrase
        return intent
    }

    func pauseIntent() -> INIntent {
        let episode = INMediaItem(identifier: Constants.SiriActions.pauseId,
                                  title: L10n.siriShortcutPauseTitle,
                                  type: .podcastEpisode,
                                  artwork: nil)

        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: nil, playShuffled: false, playbackRepeatMode: .none, resumePlayback: false)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPausePhrase
        return intent
    }

    func playPodcastIntent(podcast: Podcast) -> INIntent {
        playPodcastIntent(podcastTitle: podcast.title ?? L10n.podcastSingular, podcastUuid: podcast.uuid)
    }

    func playPodcastIntent(podcastTitle: String, podcastUuid: String) -> INIntent {
        var podcastArtwork: INImage? = INImage(named: "noartwork-page-dark")

        // Load the artwork from cache, or default to the no artwork image
        if let image = ImageManager.sharedManager.cachedImageFor(podcastUuid: podcastUuid, size: .grid) {
            podcastArtwork = INImage(uiImage: image)
        }

        let episode = INMediaItem(identifier: Constants.SiriActions.playPodcastId,
                                  title: L10n.siriShortcutPlayEpisodeTitle,
                                  type: .podcastEpisode,
                                  artwork: podcastArtwork)

        let podcastContainer = INMediaItem(identifier: podcastUuid,
                                           title: podcastTitle,
                                           type: .podcastShow,
                                           artwork: podcastArtwork)
        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: podcastContainer, playShuffled: false, playbackRepeatMode: .one, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPlayPodcastPhrase(podcastTitle)
        intent.setImage(podcastArtwork, forParameterNamed: \INPlayMediaIntent.mediaItems)
        intent.setImage(podcastArtwork, forParameterNamed: \INPlayMediaIntent.mediaContainer)

        return intent
    }

    func playFilterIntent(filter: EpisodeFilter) -> INIntent {
        let filterName = filter.playlistName
        let uuid = filter.uuid
        let episode = INMediaItem(identifier: Constants.SiriActions.playFilterId,
                                  title: L10n.siriShortcutPlayEpisodeTitle,
                                  type: .podcastEpisode,
                                  artwork: nil)

        let artwork = INImage(named: "siri_filters")
        let filterContainer = INMediaItem(identifier: uuid,
                                          title: filterName,
                                          type: .podcastPlaylist,
                                          artwork: artwork)
        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: filterContainer, playShuffled: false, playbackRepeatMode: .one, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPlayFilterPhrase(filterName)
        return intent
    }

    func playAllFilterIntent(filter: EpisodeFilter) -> INIntent {
        let filterName = filter.playlistName
        let uuid = filter.uuid
        let episode = INMediaItem(identifier: Constants.SiriActions.playAllFilterId,
                                  title: L10n.siriShortcutPlayAllTitle,
                                  type: .podcastEpisode,
                                  artwork: nil)

        let artwork = INImage(named: "siri_filters")
        let filterContainer = INMediaItem(identifier: uuid,
                                          title: filterName,
                                          type: .podcastPlaylist,
                                          artwork: artwork)
        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: filterContainer, playShuffled: false, playbackRepeatMode: .one, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPlayAllPhrase(filterName)
        return intent
    }

    func openFilterIntent(filter: EpisodeFilter) -> INIntent {
        let filterName = filter.playlistName
        let intent = SJOpenFilterIntent()
        intent.filterUuid = filter.uuid
        intent.filterName = filterName
        intent.suggestedInvocationPhrase = L10n.siriShortcutOpenFilterPhrase(filterName)
        return intent
    }

    func playNextIntent() -> INIntent {
        let artwork = INImage(named: "siri_upnext")
        let episode = INMediaItem(identifier: Constants.SiriActions.playUpNextId,
                                  title: L10n.siriShortcutPlayUpNextTitle,
                                  type: .podcastEpisode,
                                  artwork: artwork)

        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: nil, playShuffled: false, playbackRepeatMode: .none, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPlayUpNextPhrase
        return intent
    }

    func playSuggestedIntent() -> INIntent {
        let episode = INMediaItem(identifier: Constants.SiriActions.playSuggestedId,
                                  title: L10n.siriShortcutPlaySuggestedPodcastTitle,
                                  type: .podcastEpisode,
                                  artwork: nil)
        let artwork = INImage(named: "siri_suggested")
        let suggestedTitle = L10n.siriShortcutPlaySuggestedPodcastSuggestedTitle
        let container = INMediaItem(identifier: Constants.SiriActions.playSuggestedId,
                                    title: suggestedTitle,
                                    type: .podcastPlaylist,
                                    artwork: artwork)
        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: container, playShuffled: false, playbackRepeatMode: .none, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPlaySuggestedPodcastPhrase
        return intent
    }

    // MARK: - Chapter intents

    func nextChapterIntent() -> INIntent {
        let artwork = INImage(named: "siri_chapter_next")
        let episode = INMediaItem(identifier: Constants.SiriActions.nextChapterId,
                                  title: L10n.siriShortcutNextChapter,
                                  type: .podcastEpisode,
                                  artwork: artwork)

        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: nil, playShuffled: false, playbackRepeatMode: .none, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutNextChapter
        return intent
    }

    func previousChapterIntent() -> INIntent {
        let artwork = INImage(named: "siri_chapter_previous")
        let episode = INMediaItem(identifier: Constants.SiriActions.previousChapterId,
                                  title: L10n.siriShortcutPreviousChapter,
                                  type: .podcastEpisode,
                                  artwork: artwork)

        let intent = INPlayMediaIntent(mediaItems: [episode], mediaContainer: nil, playShuffled: false, playbackRepeatMode: .none, resumePlayback: true)
        intent.suggestedInvocationPhrase = L10n.siriShortcutPreviousChapter
        return intent
    }

    // MARK: - Timer intents

    func setSleepTimerIntent() -> INIntent {
        let intent = SJSleepTimerIntent()
        intent.minutes = Settings.customSleepTime() as NSNumber
        let formattedTime = TimeFormatter.shared.minutesHoursFormatted(time: Settings.customSleepTime())
        intent.suggestedInvocationPhrase = L10n.siriShortcutExtendSleepTimer(formattedTime)
        return intent
    }

    func setExtendSleepTimerIntent() -> INIntent {
        let intent = SJExtendSleepTimerIntent()
        intent.minutes = 5
        intent.suggestedInvocationPhrase = L10n.siriShortcutExtendSleepTimerFiveMin
        return intent
    }

    // MARK: - Donate Actions to siri

    func donatePodcastPlayed(podcastUuid: String) {
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) else { return }

        let intent = playPodcastIntent(podcast: podcast)
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate(completion: nil)
    }

    func donateFilterPlayed(filterUuid: String) {
        guard let filter = DataManager.sharedManager.findFilter(uuid: filterUuid) else { return }

        let intent = playFilterIntent(filter: filter)
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate(completion: nil)
    }

    // MARK: - Functions that perform the shortcuts

    func resumePlayback() -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriResume()
        if PlaybackManager.shared.currentEpisode() != nil {
            AnalyticsPlaybackHelper.shared.currentSource = analyticsSource
            PlaybackManager.shared.play()
            return INPlayMediaIntentResponseCode.success
        }
        return INPlayMediaIntentResponseCode.failureNoUnplayedContent
    }

    func pausePlayback() -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriPause()
        AnalyticsPlaybackHelper.shared.currentSource = analyticsSource
        PlaybackManager.shared.pause()
        return INPlayMediaIntentResponseCode.success
    }

    func playUpNext() -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriUpNext()
        // unlike when the user taps an episode in Up Next, their intention here is probably to remove the currently playing episode, and go to the next one if it exists
        guard let currentEpisode = PlaybackManager.shared.currentEpisode(), PlaybackManager.shared.queue.upNextCount() > 0 else {
            return INPlayMediaIntentResponseCode.failureNoUnplayedContent
        }
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: currentEpisode, fireNotification: true, userInitiated: true)
        return INPlayMediaIntentResponseCode.success
    }

    func playSuggested() -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriSurpriseMe()
        let recommendationHelper = RecommendationHelper()
        guard let episodeInfo = recommendationHelper.recommendEpisode() else {
            return INPlayMediaIntentResponseCode.failureRequiringAppLaunch
        }

        if let episode = DataManager.sharedManager.findEpisode(uuid: episodeInfo.uuid) {
            AnalyticsPlaybackHelper.shared.currentSource = analyticsSource
            PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
        } else {
            ServerPodcastManager.shared.addFromUuid(podcastUuid: episodeInfo.podcastUuid, subscribe: false, completion: { [weak self] success in
                if let episode = DataManager.sharedManager.findEpisode(uuid: episodeInfo.uuid), success {
                    AnalyticsPlaybackHelper.shared.currentSource = self?.analyticsSource
                    PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
                }
            })
        }
        return INPlayMediaIntentResponseCode.success
    }

    func skipToNextChapter() -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriChapterChanged()

        PlaybackManager.shared.skipToNextChapter(startPlaybackAfterSkip: true)
        return INPlayMediaIntentResponseCode.success
    }

    func skipToPreviousChapter() -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriChapterChanged()

        PlaybackManager.shared.skipToPreviousChapter(startPlaybackAfterSkip: true)
        return INPlayMediaIntentResponseCode.success
    }

    func skipToNextEpisode() { // ? in podcast or playlist
    }

    func sleepTimer(newTime: Int) -> Bool {
        AnalyticsHelper.siriSleeptimer()
        guard let timeInterval = TimeInterval(exactly: newTime) else { return false }
        PlaybackManager.shared.setSleepTimerInterval(timeInterval)
        return true
    }

    func extendSleepTimer(addTime: Int) -> Bool {
        AnalyticsHelper.siriSleeptimer()
        guard let minutes = TimeInterval(exactly: addTime) else { return false }
        let sixtySeconds: TimeInterval = 1.minutes
        let addSeconds = sixtySeconds * minutes
        PlaybackManager.shared.sleepTimeRemaining += addSeconds
        return true
    }

    func playFilter(uuid: String) -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriPlayTopFilter()
        guard let filter = DataManager.sharedManager.findFilter(uuid: uuid) else {
            return INPlayMediaIntentResponseCode.failureUnknownMediaType
        }

        let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: 1)
        if let topEpisode = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil).first {
            AnalyticsPlaybackHelper.shared.currentSource = analyticsSource
            PlaybackManager.shared.load(episode: topEpisode, autoPlay: true, overrideUpNext: false)
            return INPlayMediaIntentResponseCode.success
        } else {
            return INPlayMediaIntentResponseCode.failureNoUnplayedContent
        }
    }

    func playAllFilter(uuid: String) -> INPlayMediaIntentResponseCode {
        guard let filter = DataManager.sharedManager.findFilter(uuid: uuid) else {
            return INPlayMediaIntentResponseCode.failureUnknownMediaType
        }

        PlaybackManager.shared.play(filter: filter)
        return INPlayMediaIntentResponseCode.success
    }

    func playPodcast(uuid: String) -> INPlayMediaIntentResponseCode {
        AnalyticsHelper.siriPlayPodcast()
        guard let podcast = DataManager.sharedManager.findPodcast(uuid: uuid) else {
            return INPlayMediaIntentResponseCode.failureUnknownMediaType
        }

        let episodeSortOrder = podcast.podcastSortOrder

        let sortStr = PodcastEpisodeSortOrder.newestToOldest == episodeSortOrder ? "DESC" : "ASC"
        let query = "podcast_id = \(podcast.id) AND playingStatus <> \(PlayingStatus.completed.rawValue) AND archived = 0 ORDER BY publishedDate \(sortStr), addedDate \(sortStr) LIMIT 1"
        if let topEpisode = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil).first {
            AnalyticsPlaybackHelper.shared.currentSource = analyticsSource
            PlaybackManager.shared.load(episode: topEpisode, autoPlay: true, overrideUpNext: false)
            return INPlayMediaIntentResponseCode.success
        } else {
            return INPlayMediaIntentResponseCode.failureNoUnplayedContent
        }
    }

    @objc func publishSubscribedPodcasts() {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId) else { return }
        let podcasts = DataManager.sharedManager.allPodcastsOrderedByTitle()

        var searchPodcasts = [SiriPodcastItem]()
        for podcast in podcasts {
            if let podcastTitle = podcast.title {
                let thisItem = SiriPodcastItem(name: podcastTitle, uuid: podcast.uuid)
                searchPodcasts.append(thisItem)
            }
        }
        do {
            let serializedItems = try JSONEncoder().encode(searchPodcasts)
            sharedDefaults.set(serializedItems, forKey: SharedConstants.GroupUserDefaults.siriSearchItems)
            sharedDefaults.synchronize()
        } catch {
            FileLog.shared.addMessage("Unable to encode data for Siri Podcast Search: \(error.localizedDescription)")
        }
    }
}
