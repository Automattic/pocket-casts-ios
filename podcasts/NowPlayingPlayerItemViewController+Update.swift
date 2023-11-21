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
        addCustomObserver(.episodeEmbeddedArtworkLoaded, selector: #selector(update))
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
        updateChapterInfoWithChapters(PlaybackManager.shared.currentChapters())

    }

    private func updateChapterInfoForTime(_ time: TimeInterval) {
        updateChapterInfoWithChapters(PlaybackManager.shared.chaptersForTime(time: time))
    }

    private func updateChapterInfoWithChapters(_ chapters: Chapters) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }
        if let visibleChapter = chapters.visibleChapter, PlaybackManager.shared.chapterCount() != 0 {
            episodeInfoView.isHidden = true
            chapterInfoView.isHidden = false

            chapterName.text = chapters.title.count > 0 ? chapters.title : playingEpisode.displayableTitle()

            chapterSkipBackBtn.isEnabled = !visibleChapter.isFirst
            chapterSkipFwdBtn.isEnabled = !visibleChapter.isLast
            chapterCounter.text = L10n.playerChapterCount((visibleChapter.index + 1).localized(), PlaybackManager.shared.chapterCount().localized())

            if let artwork = chapters.artwork {
                showingCustomImage = true
                episodeImage.image = artwork
                episodeImage.accessibilityLabel = L10n.playerArtwork(chapterName.text ?? "")
            } else if showingCustomImage {
                showingCustomImage = false
                ImageManager.sharedManager.loadImage(episode: playingEpisode, imageView: episodeImage, size: .page)
                episodeImage.accessibilityLabel = L10n.playerArtwork(playingEpisode.title ?? "")
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
        guard let chapter = chapter else {
            return
        }
        
        if !chapter.shouldPlay {
            PlaybackManager.shared.skipToNextChapter()
            return
        }

        let remainingTime = chapter.duration + chapter.startTime.seconds - playheadPosition
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

        // TODO, buffering: bufferingLabel.isHidden = !PlaybackManager.shared.buffering()
    }

    func updateProvisionalChapterInfoForTime(time: TimeInterval) {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        if PlaybackManager.shared.chapterCount() == 0 {
            return
        }
        let chapters = PlaybackManager.shared.chaptersForTime(time: time)
        if chapters.count > 0 {
            episodeName.text = chapters.title.count > 0 ? chapters.title : playingEpisode.displayableTitle()
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
        if timeSlider.isScrubbing() || PlaybackManager.shared.isSeeking() { return }

        updateUpTo(upTo: PlaybackManager.shared.currentTime(), duration: PlaybackManager.shared.duration(), moveSlider: true)

        if !chapterSkipFwdBtn.isHidden {
            updateChapterProgress()
        }
    }
}
