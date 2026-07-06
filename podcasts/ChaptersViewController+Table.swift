import Foundation
import SafariServices
import PocketCastsUtils

extension ChaptersViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    private static let chapterCell = "ChapterCell"

    func registerCells() {
        chaptersTable.register(UINib(nibName: "PlayerChapterCell", bundle: nil), forCellReuseIdentifier: ChaptersViewController.chapterCell)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewHandler?.scrollViewDidScroll?(scrollView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PlaybackManager.shared.chapterCount(onlyPlayable: !isTogglingChapters)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chapterCell = tableView.dequeueReusableCell(withIdentifier: ChaptersViewController.chapterCell, for: indexPath) as! PlayerChapterCell

        if let chapter = isTogglingChapters ? PlaybackManager.shared.chapterAt(index: indexPath.row) : PlaybackManager.shared.playableChapterAt(index: indexPath.row) {
            var state = PlayerChapterCell.ChapterPlayState.played
            let currentChapters = PlaybackManager.shared.currentChapters()

            if chapter.index == currentChapters.index {
                state = PlaybackManager.shared.playing() ? .currentlyPlaying : .currentlyPaused
            } else if chapter.index > currentChapters.index {
                state = .future
            }

            chapterCell.populateFrom(chapter: chapter, playState: state, isChapterToggleEnabled: isTogglingChapters) { [weak self] url in
                if Settings.openLinks {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    self?.present(SFSafariViewController(with: url), animated: true)
                }
            }

            chapterCell.seperatorView.isHidden = (chapter.index == PlaybackManager.shared.currentChapters().index - 1 || chapter.index == PlaybackManager.shared.currentChapters().index || (indexPath.row == PlaybackManager.shared.chapterCount() - 1))
        }

        chapterCell.setResolving(indexPath == resolvingIndexPath)

        return chapterCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard !isTogglingChapters else {
            // Ensure at least one chapter is selected
            if PlaybackManager.shared.chapterAt(index: indexPath.row)?.isPlayable() == true, PlaybackManager.shared.chapterCount(onlyPlayable: true) == 1 {
                Toast.show(L10n.selectAChapter)
                return
            }

            (tableView.cellForRow(at: indexPath) as? PlayerChapterCell)?.toggleChapterTapped(self)
            return
        }

        if let chapter = PlaybackManager.shared.playableChapterAt(index: indexPath.row) {
            if chapter.index == PlaybackManager.shared.currentChapters().index {
                containerDelegate?.scrollToNowPlaying()
            } else if shouldUseFingerprintSeek {
                resolveAndSeek(to: chapter, at: indexPath)
            } else {
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
                PlaybackManager.shared.trackChapterEvent(.playerChapterSelected)
            }
        }
    }

    /// Generated chapters carry reference-timeline start times that dynamic ads
    /// have shifted in the listener's audio, so seeking to the raw start lands in
    /// the wrong place. When both the generated-chapters and fingerprint features
    /// are on, resolve the true playback position by fingerprinting instead.
    /// Embedded / podcast-index chapters already carry real playback times and
    /// must not go through the resolver.
    private var shouldUseFingerprintSeek: Bool {
        FeatureFlag.generatedChapters.enabled
            && FeatureFlag.syncedTranscripts.enabled
            && PlaybackManager.shared.chaptersAreGenerated
            && PlaybackManager.shared.currentEpisode() != nil
    }

    private func resolveAndSeek(to chapter: ChapterInfo, at indexPath: IndexPath) {
        guard let episode = PlaybackManager.shared.currentEpisode() else {
            PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
            PlaybackManager.shared.trackChapterEvent(.playerChapterSelected)
            return
        }

        let episodeUuid = episode.uuid
        let referenceTime = chapter.startTime.seconds
        let fromPosition = PlaybackManager.shared.currentTime()

        // Move the spinner to the tapped row (clearing any previous one).
        if let previous = resolvingIndexPath, previous != indexPath {
            (chaptersTable.cellForRow(at: previous) as? PlayerChapterCell)?.setResolving(false)
        }
        resolvingIndexPath = indexPath
        (chaptersTable.cellForRow(at: indexPath) as? PlayerChapterCell)?.setResolving(true)
        PlaybackManager.shared.trackChapterEvent(.playerChapterSelected)

        FingerprintTimingManager.shared.resolvePlaybackTime(forReferenceTime: referenceTime, episode: episode) { [weak self] result in
            guard let self else { return }

            self.resolvingIndexPath = nil
            (self.chaptersTable.cellForRow(at: indexPath) as? PlayerChapterCell)?.setResolving(false)

            // The listener switched episodes while we were resolving — the
            // resolved position is meaningless now, so don't seek.
            guard PlaybackManager.shared.currentEpisode()?.uuid == episodeUuid else {
                Analytics.track(.syncedTranscriptsChapterSeekFailed, properties: [
                    "episode_uuid": episodeUuid,
                    "reason": "episode_changed",
                    "synced_state": FingerprintTimingManager.shared.state.analyticsName,
                    "is_streaming": false
                ])
                return
            }

            switch result {
            case let .resolved(playbackTime, usedPrior, isStreaming, resolveDurationMs):
                let seekTime = ceil(playbackTime)
                // Record where the chapter actually starts on the playback timeline
                // so its progress bar fills from 0% rather than from the ad-shifted
                // offset (see `ChapterInfo.effectiveStartTime`).
                chapter.resolvedPlaybackStartTime = seekTime
                PlaybackManager.shared.seekTo(time: seekTime, startPlaybackAfterSeek: true)
                Analytics.track(.syncedTranscriptsChapterSeekUsed, properties: [
                    "episode_uuid": episodeUuid,
                    "from_position_seconds": Int(fromPosition),
                    "to_position_seconds": Int(seekTime),
                    "reference_time_seconds": Int(referenceTime),
                    "resolve_duration_ms": resolveDurationMs,
                    "used_prior": usedPrior,
                    "is_streaming": isStreaming
                ])

            case let .unresolved(reason, isStreaming):
                // Graceful fallback: seek to the raw reference-timeline start.
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
                if reason == "region_not_local" {
                    Toast.show(L10n.transcriptTapToSeekStreamingUnavailable)
                }
                Analytics.track(.syncedTranscriptsChapterSeekFailed, properties: [
                    "episode_uuid": episodeUuid,
                    "reason": reason,
                    "synced_state": FingerprintTimingManager.shared.state.analyticsName,
                    "is_streaming": isStreaming
                ])
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        shouldShowDeselectChaptersHeader ? 44 : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        shouldShowDeselectChaptersHeader ? UITableView.automaticDimension : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return header
    }

    var shouldShowDeselectChaptersHeader: Bool {
        PlaybackManager.shared.currentEpisode()?.isUserEpisode == false
    }
}

extension ChaptersViewController: ChaptersHeaderDelegate {
    func toggleTapped() {
        guard PaidFeature.deselectChapters.isUnlocked else {
            PaidFeature.deselectChapters.presentUpgradeController(from: self, source: .deselectChapters, customTitle: PaidFeature.deselectChapters.tier == .plus ? L10n.skipChaptersPlusPrompt : L10n.skipChaptersPatronPrompt)
            return
        }

        isTogglingChapters.toggle()
        chaptersTable.reloadSections([0], with: .automatic)
        header.isTogglingChapters = isTogglingChapters
        header.update()
        updateSize()
        playbackManager.playableChaptersUpdated()

        if isTogglingChapters {
            numberOfDeselectedChapters = playbackManager.chapterCount(onlyPlayable: true)
            PlaybackManager.shared.trackChapterEvent(.deselectChaptersToggledOn)
        } else {
            numberOfDeselectedChapters -= playbackManager.chapterCount(onlyPlayable: true)
            PlaybackManager.shared.trackChapterEvent(.deselectChaptersToggledOff, properties: ["number_of_deselected_chapters": numberOfDeselectedChapters])
        }
    }
}
