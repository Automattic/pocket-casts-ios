import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension EpisodeDetailViewController {
    // MARK: - Button Actions

    @IBAction func upNextTapped(_ sender: UIButton) {
        if PlaybackManager.shared.inUpNext(episode: episode) {
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
        } else if PlaybackManager.shared.queue.upNextCount() < 1 {
            PlaybackManager.shared.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: false, userInitiated: true)
        } else {
            let addToUpNextPicker = OptionsPicker(title: L10n.addToUpNext.localizedUppercase)
            let playNextAction = OptionAction(label: L10n.playNext, icon: "list_playnext") {
                PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
            }
            addToUpNextPicker.addAction(action: playNextAction)

            let playLastAction = OptionAction(label: L10n.playLast, icon: "list_playlast") {
                PlaybackManager.shared.addToUpNext(episode: self.episode, ignoringQueueLimit: true, toTop: false, userInitiated: true)
            }
            addToUpNextPicker.addAction(action: playLastAction)

            addToUpNextPicker.show(statusBarStyle: preferredStatusBarStyle)
        }
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
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            // dismiss the dialog if the user hit play
            if !PlaybackManager.shared.playing() {
                dismiss(animated: true, completion: nil)
            }

            PlaybackActionHelper.playPause()
        } else {
            dismiss(animated: true, completion: nil)
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

        upNextBtn.setTitle(L10n.upNext, for: .normal)
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) || playbackManager.inUpNext(episode: episode) {
            upNextBtn.setImage(UIImage(named: "episode-removenext"), for: .normal)
            upNextBtn.accessibilityLabel = L10n.removeFromUpNext
        } else {
            upNextBtn.setImage(UIImage(named: "episode-playnext"), for: .normal)
            upNextBtn.accessibilityLabel = L10n.upNext
        }

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
        } else if episode.played() {
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
        } else if !episode.archived, episode.excludeFromEpisodeLimit, podcast.autoArchiveEpisodeLimit > 0 {
            setMessage(title: L10n.podcastDetailsManualUnarchiveTitle,
                       details: L10n.podcastDetailsManualUnarchiveMsg(podcast.autoArchiveEpisodeLimit.localized()),
                       imageName: "episode-archive")
        } else if buttonBottomOffsetConstraint.constant != 20 {
            messageView.isHidden = true
            buttonBottomOffsetConstraint.constant = 20
        }
    }

    private func setMessage(title: String, details: String, imageName: String) {
        messageTitle.text = title
        messageDetails.text = details
        messageIcon.image = UIImage(named: imageName)

        messageView.isHidden = false
        buttonBottomOffsetConstraint.constant = messageView.bounds.height + 40
    }

    // MARK: - Helpers

    private func deleteDownloadedFile() {
        EpisodeManager.analyticsHelper.currentSource = analyticsSource

        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: false)
        EpisodeManager.deleteDownloadedFiles(episode: episode, userInitated: true)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
    }
}
