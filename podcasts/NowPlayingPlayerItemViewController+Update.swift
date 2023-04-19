import Foundation
import PocketCastsServer
import PocketCastsUtils

extension NowPlayingPlayerItemViewController {
    func addObservers() {
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(progressUpdated))
        addCustomObserver(Constants.Notifications.episodeDurationChanged, selector: #selector(progressUpdated))
        addCustomObserver(Constants.Notifications.playbackStarted, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackPaused, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(playbackTrackChanged))
        addCustomObserver(Constants.Notifications.videoPlaybackEngineSwitched, selector: #selector(videoPlaybackEngineSwitched))
        addCustomObserver(Constants.Notifications.podcastChaptersDidUpdate, selector: #selector(update))
        addCustomObserver(Constants.Notifications.googleCastStatusChanged, selector: #selector(update))
        addCustomObserver(Constants.Notifications.playbackEffectsChanged, selector: #selector(update))
        addCustomObserver(Constants.Notifications.episodeEmbeddedArtworkLoaded, selector: #selector(update))
        addCustomObserver(Constants.Notifications.podcastChapterChanged, selector: #selector(updateChapterInfo))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(update))
        addCustomObserver(Constants.Notifications.sleepTimerChanged, selector: #selector(sleepTimerUpdated))
        addCustomObserver(Constants.Notifications.playerActionsUpdated, selector: #selector(reloadShelfActions))
        addCustomObserver(UIApplication.willEnterForegroundNotification, selector: #selector(update))
    }

    @objc private func playbackTrackChanged() {
        floatingVideoView.isHidden = true
        update()
    }

    @objc private func videoPlaybackEngineSwitched() {
        floatingVideoView.player = PlaybackManager.shared.internalPlayerForVideoPlayback()
    }

    @objc func update() {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        if playingEpisode.videoPodcast() {
            if floatingVideoView.isHidden {
                floatingVideoView.isHidden = false
                floatingVideoView.player = PlaybackManager.shared.internalPlayerForVideoPlayback()
                episodeImage.alpha = CGFloat.leastNonzeroMagnitude
            }
        } else {
            floatingVideoView.player = nil
            floatingVideoView.isHidden = true
            episodeImage.alpha = 1.0
        }

        let skipBackAmount = ServerSettings.skipBackTime()
        skipBackBtn.skipAmount = skipBackAmount

        let skipFwdAmount = ServerSettings.skipForwardTime()
        skipFwdBtn.skipAmount = skipFwdAmount

        updatePlayPauseButton(isPlaying: PlaybackManager.shared.playing())
        updateUpTo(upTo: PlaybackManager.shared.currentTime(), duration: PlaybackManager.shared.duration(), moveSlider: true)
        reloadShelfActions()
        updateChaptersControls()
        updateChapterInfo()
        updateChapterProgress()
        updateColors()

        if !showingCustomImage {
            ImageManager.sharedManager.loadImage(episode: playingEpisode, imageView: episodeImage, size: .page)
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
        timeSlider.circleColor = buttonColor
        timeSlider.rightColor = ThemeColor.playerContrast06()
        timeSlider.popupColor = ThemeColor.playerContrast06()
        timeSlider.popupTextColor = ThemeColor.playerContrast01()

        chromecastBtn.activeTintColor = highlightColor
    }

    func updatePlayPauseButton(isPlaying: Bool) {
        playPauseBtn.isPlaying = isPlaying
    }

    @objc func updateChapterInfo() {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        if let chapter = PlaybackManager.shared.currentChapter(), PlaybackManager.shared.chapterCount() != 0 {
            episodeInfoView.isHidden = true
            chapterInfoView.isHidden = false
            // we've already displayed this chapter, don't waste cycles re-rendering it
            if chapter.index == lastChapterIndexRendered { return }
            lastChapterIndexRendered = chapter.index

            chapterName.text = chapter.title.count > 0 ? chapter.title : playingEpisode.displayableTitle()

            chapterSkipBackBtn.isEnabled = !chapter.isFirst
            chapterSkipFwdBtn.isEnabled = !chapter.isLast
            chapterCounter.text = L10n.playerChapterCount((chapter.index + 1).localized(), PlaybackManager.shared.chapterCount().localized())
            chapterLink.isHidden = chapter.url == nil
            if let image = chapter.image {
                showingCustomImage = true
                episodeImage.image = image
                episodeImage.accessibilityLabel = L10n.playerArtwork(chapterName.text ?? "")
            } else if showingCustomImage {
                showingCustomImage = false
                ImageManager.sharedManager.loadImage(episode: playingEpisode, imageView: episodeImage, size: .page)
                episodeImage.accessibilityLabel = L10n.playerArtwork(playingEpisode.title ?? "")
            }
        } else {
            episodeInfoView.isHidden = false
            chapterInfoView.isHidden = true
            episodeName.text = playingEpisode.displayableTitle()
            podcastName.text = playingEpisode.subTitle()
            showingCustomImage = false
            chapterLink.isHidden = true
        }
    }

    func updateChapterProgress() {
        guard let currentChapter = PlaybackManager.shared.currentChapter() else { return }

        let remainingTime = currentChapter.duration + currentChapter.startTime.seconds - PlaybackManager.shared.currentTime()
        chapterTimeLeftLabel.text = TimeFormatter.shared.singleUnitFormattedShortestTime(time: remainingTime)
        let percentageCompleted = 1 - (remainingTime / currentChapter.duration)
        chapterProgress.startingAngle = CGFloat((percentageCompleted * 360) - 90)
    }

    private func updateTimeLabels(upTo: TimeInterval, remaining: TimeInterval) {
        timeElapsed.text = TimeFormatter.shared.playTimeFormat(time: upTo)
        timeRemaining.text = "-\(TimeFormatter.shared.playTimeFormat(time: remaining))"
    }

    func updateUpTo(upTo: TimeInterval, duration: TimeInterval, moveSlider: Bool) {
        let remaining = max(0, duration - upTo)
        updateTimeLabels(upTo: upTo, remaining: remaining)

        if moveSlider {
            timeSlider.totalDuration = duration

            timeSlider.currentTime = upTo
        }

        // TODO, buffering: bufferingLabel.isHidden = !PlaybackManager.shared.buffering()
    }

    func updateProvisionalChapterInfoForTime(time: TimeInterval) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        if PlaybackManager.shared.chapterCount() == 0 {
            return
        }

        if let chapter = PlaybackManager.shared.chapterForTime(time: time) {
            episodeName.text = chapter.title.count > 0 ? chapter.title : playingEpisode.displayableTitle()

            chapterCounter.text = L10n.playerChapterCount((chapter.index + 1).localized(), PlaybackManager.shared.chapterCount().localized())
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
        if timeSlider.isScrubbing() || PlaybackManager.shared.isSeeking() { return }

        updateUpTo(upTo: PlaybackManager.shared.currentTime(), duration: PlaybackManager.shared.duration(), moveSlider: true)

        if !chapterSkipFwdBtn.isHidden {
            updateChapterProgress()
        }
    }
}
