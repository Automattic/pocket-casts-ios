import Foundation
import PocketCastsServer
import PocketCastsUtils
import PocketCastsDataModel
import SafariServices

extension NowPlayingPlayerItemViewController {
    func addObservers() {
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(progressUpdated))
        addCustomObserver(Constants.Notifications.episodeDurationChanged, selector: #selector(progressUpdated))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(update(notification:)))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(update(notification:)))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(playbackTrackChanged))
        addCustomObserver(Constants.Notifications.videoPlaybackEngineSwitched, selector: #selector(videoPlaybackEngineSwitched))
        addCustomObserver(Constants.Notifications.videoRenderingToggled, selector: #selector(videoPlaybackEngineSwitched))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(update(notification:)))
        addCustomObserver(Constants.Notifications.googleCastStatusChanged, selector: #selector(update(notification:)))
        addCustomObserver(Constants.Notifications.playbackEffectsChanged, selector: #selector(update(notification:)))
        addCustomObserver(.episodeEmbeddedArtworkLoaded, selector: #selector(update(notification:)))
        addCustomObserver(Constants.Notifications.podcastChapterChanged, selector: #selector(updateChapterInfo))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(update(notification:)))
        addCustomObserver(UIApplication.willEnterForegroundNotification, selector: #selector(update(notification:)))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(update(notification:)))

        addCustomObserver(Constants.Notifications.sleepTimerChanged, selector: #selector(sleepTimerUpdated))
        addCustomObserver(Constants.Notifications.playerActionsUpdated, selector: #selector(reloadShelfActions))
        #if !APPCLIP
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(reloadShelfActions))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(reloadShelfActions))
        #endif
    }

    @objc private func playbackTrackChanged() {
        floatingVideoView.isHidden = true
        update(notification: nil)
    }

    @objc private func videoPlaybackEngineSwitched() {
        // Video may have been detected at runtime (e.g. an HLS stream) or toggled via the shelf,
        // so refresh to reveal or hide the view accordingly.
        if PlaybackManager.shared.shouldRenderVideo() {
            floatingVideoView.player = PlaybackManager.shared.internalPlayerForVideoPlayback()
        }
        update(notification: nil)
    }

    @objc func update(notification: NSNotification?) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode else { return }

        if PlaybackManager.shared.shouldRenderVideo() {
            if floatingVideoView.isHidden {
                floatingVideoView.isHidden = false
                floatingVideoView.player = PlaybackManager.shared.internalPlayerForVideoPlayback()
                episodeImage.alpha = CGFloat.leastNonzeroMagnitude
            }
        } else {
            let wasShowingVideo = !floatingVideoView.isHidden
            floatingVideoView.player = nil
            floatingVideoView.isHidden = true
            episodeImage.alpha = 1.0
            episodeImage.layer.opacity = 1
            // The player-open zoom transition (PlayerZoomAnimator) leaves the artwork subview at
            // alpha 0 when the player opens with video showing, since the video covers it. Restore it
            // here so the cover art reappears once video is turned off.
            artworkImageView.alpha = 1
            if wasShowingVideo {
                // The artwork slot was invisible while the video was showing, so its aspect-fit
                // subview may not have been laid out yet. Force a pass so the artwork (reloaded at
                // the end of this method) appears the first time.
                episodeImage.layoutIfNeeded()
            }
        }

        let skipBackAmount = Settings.skipBackTime
        skipBackBtn.skipAmount = skipBackAmount

        let skipFwdAmount = Settings.skipForwardTime
        skipFwdBtn.skipAmount = skipFwdAmount

        updatePlayPauseButton(isPlaying: PlaybackManager.shared.isPlaying)
        updateUpTo(upTo: PlaybackManager.shared.currentTime(), duration: PlaybackManager.shared.duration(), moveSlider: true)
        reloadShelfActions()
        updateChaptersControls()
        updateChapterInfo()
        updateChapterProgress()
        updateColors()
        let errorRelevantNotifications = Set([Constants.Notifications.playbackFailed, Constants.Notifications.playbackStarted, Constants.Notifications.playbackPaused])
        if let notificationName = notification?.name, errorRelevantNotifications.contains(notificationName) {
            updateError()
        }
        if !showingCustomImage {
            ImageManager.sharedManager.loadImage(episode: playingEpisode, imageView: artworkImageView, size: .page)
        }
    }

    private func updateColors() {
        let backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        view.backgroundColor = backgroundColor
        playPauseBtn.playButtonColor = backgroundColor

        let buttonColor = ThemeColor.playerContrast01()
        playPauseBtn.circleColor = buttonColor
        skipBackBtn.tintColor = buttonColor
        skipFwdBtn.tintColor = buttonColor

        let highlightColor = PlayerColorHelper.playerHighlightColor01(for: .dark)
        timeSlider.leftColor = highlightColor
        timeSlider.animationColor = PlayerColorHelper.playerHighlightColor01(for: .dark).withAlphaComponent(0.2)
        timeSlider.circleColor = buttonColor
        timeSlider.rightColor = ThemeColor.playerContrast06()
        timeSlider.popupColor = ThemeColor.playerContrast06()
        timeSlider.popupTextColor = ThemeColor.playerContrast01()

        #if !APPCLIP
        chromecastBtn.activeTintColor = highlightColor
        #endif
    }

    func updatePlayPauseButton(isPlaying: Bool) {
        playPauseBtn.isPlaying = isPlaying
    }

    @objc func updateChapterInfo() {
        updateChapterInfoWithChapters(PlaybackManager.shared.currentChapters())
    }

    private func updateChapterInfoForTime(_ time: TimeInterval) {
        updateChapterInfoWithChapters(PlaybackManager.shared.chaptersForTime(time: time))
    }

    private func updateChapterInfoWithChapters(_ chapters: Chapters) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode else { return }
        if let visibleChapter = chapters.visibleChapter, PlaybackManager.shared.chapterCount() != 0 {
            episodeInfoView.isHidden = true
            chapterInfoView.isHidden = false

            chapterName.text = !chapters.title.isEmpty ? chapters.title : playingEpisode.displayableTitle()

            chapterSkipBackBtn.isEnabled = !visibleChapter.isFirst
            chapterSkipFwdBtn.isEnabled = !visibleChapter.isLast
            chapterCounter.text = L10n.playerChapterCount((visibleChapter.index + 1).localized(), PlaybackManager.shared.chapterCount().localized())

            if let artwork = chapters.artwork {
                showingCustomImage = true
                artworkImageView.image = artwork
                artworkImageView.accessibilityLabel = L10n.playerArtwork(chapterName.text ?? "")
            } else if showingCustomImage {
                showingCustomImage = false
                ImageManager.sharedManager.loadImage(episode: playingEpisode, imageView: artworkImageView, size: .page)
                artworkImageView.accessibilityLabel = L10n.playerArtwork(playingEpisode.title ?? "")
            }
            chapterLink.isHidden = chapters.url == nil
        } else {
            episodeInfoView.isHidden = false
            chapterInfoView.isHidden = true
            episodeName.text = playingEpisode.displayableTitle()
            podcastName.text = playingEpisode.subTitle()
            showingCustomImage = false
            chapterLink.isHidden = true
        }
    }

    private func updateChapterProgress(for chapter: ChapterInfo?, playheadPosition: TimeInterval) {
        guard let chapter else {
            return
        }

        // Current-chapter detection keys off the raw `startTime`, so the playhead
        // can be inside the chapter's reference window but before its resolved
        // playback start — clamp to [0, duration] so the ring can't run backwards
        // or overshoot.
        let remainingTime = min(chapter.duration, max(0, chapter.duration + chapter.effectiveStartTime - playheadPosition))
        chapterTimeLeftLabel.text = TimeFormatter.shared.singleUnitFormattedShortestTime(time: remainingTime)
        let percentageCompleted = 1 - (remainingTime / chapter.duration)
        chapterProgress.startingAngle = CGFloat((percentageCompleted * 360) - 90)
    }

    func updateChapterProgress() {
        updateChapterProgress(for: PlaybackManager.shared.currentChapters().visibleChapter, playheadPosition: PlaybackManager.shared.currentTime())
    }

    private func updateTimeLabels(upTo: TimeInterval, remaining: TimeInterval) {
        timeElapsed.text = TimeFormatter.shared.playTimeFormat(time: upTo)
        timeRemaining.text = "-\(TimeFormatter.shared.playTimeFormat(time: remaining))"
    }

    func updateUpTo(upTo: TimeInterval, duration: TimeInterval, moveSlider: Bool) {
        let remaining = max(0, duration - upTo)
        updateTimeLabels(upTo: upTo, remaining: remaining)
        updateChapterInfoWithChapters(PlaybackManager.shared.chaptersForTime(time: upTo))

        if moveSlider {
            timeSlider.totalDuration = duration

            timeSlider.currentTime = upTo
        }

        timeSlider.indeterminant = PlaybackManager.shared.isBuffering && PlaybackManager.shared.isPlaying
    }

    var isErrorVisible: Bool {
        return errorBottomSpacing.constant == 0
    }

    @objc func updateError() {
        guard FeatureFlag.displayErrorsOnPlayer.enabled else {
            hideError()
            return
        }
        guard PlaybackManager.shared.currentEpisode != nil,
              let error = PlaybackManager.shared.activeError else {
            hideError()
            return
        }
        if !isErrorVisible {
            showError(error, dismissAfter: 5)
        }
    }

    func showError(_ error: PlaybackManager.PlaybackError, dismissAfter seconds: TimeInterval?) {
        AnalyticsPlaybackHelper.shared.playbackErrorShown(playerSource: .fullPlayer)
        // Move error container in view
        errorLabel.attributedText = error.shortUserAttributedMessage(mainColor: ThemeColor.playerContrast02(), interactiveColor: ThemeColor.primaryInteractive01())
        errorContainer.layoutIfNeeded()
        errorBottomSpacing.constant = 0
        playerBottomSpacing.constant = 16
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseInOut) {
            [weak self] in
            self?.view.layoutIfNeeded()
        }

        errorAutoDismissWork?.cancel()
        if let seconds {
            let work = DispatchWorkItem { [weak self] in self?.hideError() }
            errorAutoDismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
        }
    }

    func hideError() {
        // Move error out
        errorBottomSpacing.constant = -48
        playerBottomSpacing.constant = 30
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseInOut) {
            [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    @objc func errorTapped() {
        guard let error  = PlaybackManager.shared.activeError,
              let url = error.userAction
        else {
            return
        }
        AnalyticsPlaybackHelper.shared.playbackErrorTapped(playerSource: .fullPlayer)
        #if !APPCLIP
        let safariViewController = SFSafariViewController(with: url)
        safariViewController.modalPresentationStyle = .formSheet
        self.present(safariViewController, animated: true, completion: nil)
        #endif
    }

    func updateProvisionalChapterInfoForTime(time: TimeInterval) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode else { return }

        if PlaybackManager.shared.chapterCount() == 0 {
            return
        }
        let chapters = PlaybackManager.shared.chaptersForTime(time: time)
        // swiftlint:disable:next empty_count
        if chapters.count > 0 {
            episodeName.text = !chapters.title.isEmpty ? chapters.title : playingEpisode.displayableTitle()
            updateChapterProgress(for: chapters.visibleChapter, playheadPosition: time)
            updateUpTo(upTo: time, duration: chapters.duration, moveSlider: false)
            chapterCounter.text = L10n.playerChapterCount((chapters.index + 1).localized(), PlaybackManager.shared.chapterCount().localized())
        }
    }

    private func updateChaptersControls() {
        if PlaybackManager.shared.chapterCount() > 0 {
            chapterSkipBackBtn.isHidden = false
            chapterSkipFwdBtn.isHidden = false
            chapterCounter.isHidden = false
            chapterTimeLeftLabel.isHidden = false
        } else {
            chapterSkipBackBtn.isHidden = true
            chapterSkipFwdBtn.isHidden = true
            chapterCounter.isHidden = true
            chapterTimeLeftLabel.isHidden = true
        }
    }

    // MARK: - Progress

    @objc func progressUpdated() {
        if timeSlider.isScrubbing() || PlaybackManager.shared.isSeeking { return }

        updateUpTo(upTo: PlaybackManager.shared.currentTime(), duration: PlaybackManager.shared.duration(), moveSlider: true)

        if !chapterSkipFwdBtn.isHidden {
            updateChapterProgress()
        }
    }
}
