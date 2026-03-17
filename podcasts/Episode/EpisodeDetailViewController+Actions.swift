import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension EpisodeDetailViewController {
    // MARK: - Button Actions

    @IBAction func addTapped(_ sender: UIButton) {
        let addPicker = OptionsPicker(title: nil)

        let isInUpNext = PlaybackManager.shared.inUpNext(episode: episode) || PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid)

        if isInUpNext {
            let removeFromUpNextAction = OptionAction(label: L10n.removeFromUpNext, icon: "episode-removenext") { [weak self] in
                guard let self else { return }
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: self.episode, fireNotification: true, userInitiated: true)
            }
            addPicker.addAction(action: removeFromUpNextAction)
        } else {
            let playNextAction = OptionAction(label: L10n.playNextInUpNext, icon: "list_playnext") { [weak self] in
                guard let self else { return }
                PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
            }
            addPicker.addAction(action: playNextAction)

            let playLastAction = OptionAction(label: L10n.playLastInUpNext, icon: "list_playlast") { [weak self] in
                guard let self else { return }
                PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: false, userInitiated: true)
            }
            addPicker.addAction(action: playLastAction)
        }

        let addToPlaylistAction = OptionAction(label: L10n.playlistManualEpisodeAddToPlaylist, icon: "plus-circle") { [weak self] in
            guard let self else { return }
            let chooser = ManualPlaylistsChooserViewController(episode: self.episode, analyticsSource: "episode_details")
            let navVC = SJUIUtils.navController(for: chooser)
            self.present(navVC, animated: true, completion: nil)
        }
        addPicker.addAction(action: addToPlaylistAction)

        addPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    @IBAction func episodeStatusTapped(_ sender: Any) {
        AnalyticsEpisodeHelper.shared.currentSource = analyticsSource

        if episode.played() {
            EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
        } else {
            EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        }
    }

    @IBAction func archiveTapped(_ sender: Any) {
        if episode.archived {
            EpisodeManager.unarchiveEpisode(episode: episode, fireNotification: true)
        } else {
            EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func playPauseTapped(_ sender: UIButton) {
        let isNowPlaying = PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid)
        if isNowPlaying {
            // dismiss the dialog if the user hit play
            if !PlaybackManager.shared.playing() {
                dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
        playPauseEpisode(isPlaying: isNowPlaying)
    }

    func playPauseEpisode(isPlaying: Bool) {
        if isPlaying {
            if let timestamp = timestamp {
                DataManager.sharedManager.saveEpisode(playedUpTo: timestamp, episode: episode, updateSyncFlag: false)
                PlaybackManager.shared.seekTo(time: timestamp, startPlaybackAfterSeek: false)
                updateProgress()
            }

            PlaybackActionHelper.playPause()
        } else {
            if let timestamp = timestamp {
                episode.playingStatus = PlayingStatus.inProgress.rawValue
                episode.playedUpTo = timestamp
                DataManager.sharedManager.save(episode: episode)
                updateProgress()
            }
            PlaybackActionHelper.play(episode: episode, playlist: fromPlaylist)
        }
    }

    @IBAction func downloadTapped(_ sender: UIButton) {
        if episode.downloaded(pathFinder: DownloadManager.shared) {
            let confirmation = OptionsPicker(title: L10n.podcastDetailsRemoveDownload)
            let yesAction = OptionAction(label: L10n.remove, icon: nil) {
                self.deleteDownloadedFile()
                self.updateColors()
            }
            yesAction.destructive = true
            confirmation.addAction(action: yesAction)

            confirmation.show(statusBarStyle: preferredStatusBarStyle)
        } else if episode.downloading() || episode.queued() || episode.waitingForWifi() {
            PlaybackActionHelper.stopDownload(episodeUuid: episode.uuid)
        } else {
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
        }
    }

    // MARK: - UI State

    func updateButtonStates() {
        guard let updatedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid) else { return }
        episode = updatedEpisode

        let playbackManager = PlaybackManager.shared

        playPauseBtn.isPlaying = playbackManager.isActivelyPlaying(episodeUuid: episode.uuid)

        if episode.downloaded(pathFinder: DownloadManager.shared) {
            downloadBtn.setImage(UIImage(named: "episode-downloaded"), for: .normal)
            downloadBtn.setTitle(SizeFormatter.shared.noDecimalFormat(bytes: episode.sizeInBytes), for: .normal)
            downloadBtn.accessibilityLabel = L10n.removeDownload
        } else if episode.queued() || episode.downloading() || episode.waitingForWifi() {
            downloadBtn.setImage(UIImage(named: "episode-cancel"), for: .normal)
            downloadBtn.accessibilityLabel = L10n.cancelDownload
        } else {
            downloadBtn.setImage(UIImage(named: "episode-download"), for: .normal)
            let sizeAsStr = episode.sizeInBytes == 0 ? "" : SizeFormatter.shared.noDecimalFormat(bytes: episode.sizeInBytes)
            downloadBtn.setTitle(sizeAsStr == "" ? L10n.download : sizeAsStr, for: .normal)
            downloadBtn.accessibilityLabel = L10n.download
        }

        addButton.setTitle(L10n.episodeDetailAdd, for: .normal)
        addButton.setImage(UIImage(named: "episode-add"), for: .normal)
        addButton.accessibilityLabel = L10n.episodeDetailAdd

        if episode.archived {
            archiveButton.setImage(UIImage(named: "episode-unarchive"), for: .normal)
            archiveButton.setTitle(L10n.unarchive, for: .normal)
        } else {
            archiveButton.setImage(UIImage(named: "episode-archive"), for: .normal)
            archiveButton.setTitle(L10n.archive, for: .normal)
        }

        if episode.played() {
            playStatusButton.setImage(UIImage(named: "episode-markunplayed"), for: .normal)
            playStatusButton.setTitle(L10n.markUnplayedShort, for: .normal)
        } else {
            playStatusButton.setImage(UIImage(named: "episode-markasplayed"), for: .normal)
            playStatusButton.setTitle(L10n.markPlayedShort, for: .normal)
        }
    }

    func updateProgress() {
        var progress: CGFloat = 0
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            let currentTime = PlaybackManager.shared.currentTime()
            let duration = PlaybackManager.shared.duration()
            if currentTime > 0, duration > 0 {
                progress = min(1, CGFloat(currentTime / duration))
            }
        } else if let timestamp {
            progress = min(1, CGFloat(timestamp / episode.duration))
        }
        else if episode.played() {
            progress = 1
        } else if episode.playedUpTo > 0, episode.duration > 0 {
            progress = min(1, CGFloat(episode.playedUpTo / episode.duration))
        }

        if progressWidthConstraint.multiplier != progress {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.progressWidthConstraint = self.progressWidthConstraint.cloneWithMultipler(progress)
            })
        }
    }

    func updateMessageView() {
        if episode.playbackError() {
            setMessage(title: L10n.playbackFailed, details: episode.playbackErrorDetails ?? L10n.podcastDetailsPlaybackError, imageName: "option-alert")
        } else if episode.downloadFailed() {
            setMessage(title: L10n.downloadFailed, details: episode.downloadErrorDetails ?? L10n.podcastDetailsDownloadError, imageName: "option-alert")
        } else if episode.waitingForWifi() {
            setMessage(title: L10n.waitForWifi, details: L10n.podcastDetailsDownloadWifiQueue, imageName: "waiting-wifi")
        } else if !episode.archived, episode.excludeFromEpisodeLimit, podcast.autoArchiveEpisodeLimitCount > 0 {
            setMessage(title: L10n.podcastDetailsManualUnarchiveTitle,
                       details: L10n.podcastDetailsManualUnarchiveMsg(podcast.autoArchiveEpisodeLimitCount.localized()),
                       imageName: "episode-archive")
        } else {
            messageContainerView.isHidden = true
        }
    }

    private func setMessage(title: String, details: String, imageName: String) {
        messageTitle.text = title
        messageDetails.text = details
        messageIcon.image = UIImage(named: imageName)

        messageContainerView.isHidden = false
    }

    // MARK: - Helpers

    private func deleteDownloadedFile() {
        EpisodeManager.analyticsHelper.currentSource = analyticsSource

        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: false)
        EpisodeManager.deleteDownloadedFiles(episode: episode, userInitated: true)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
    }
}
