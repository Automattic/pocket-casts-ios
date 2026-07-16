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
                // Playback is already inside the tapped chapter: no seek happens, so
                // report zero latency when playing and none when paused, as Android
                // does. Cancelling first drops any previous tap's pending event, the
                // way each Android tap cancels the previous `playChapterJob`.
                chapterSelectionLatencyTracker.cancel()
                trackChapterSelected(latencyMs: PlaybackManager.shared.playing() ? 0 : nil)
            } else if GeneratedChapterSeeker.isEnabled {
                resolveAndSeek(to: chapter, at: indexPath)
            } else {
                beginTrackingChapterSelection()
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
                chapterSelectionLatencyTracker.arm(targetTime: ceil(chapter.startTime.seconds), targetDuration: chapter.duration)
            }
        }
    }

    private func resolveAndSeek(to chapter: ChapterInfo, at indexPath: IndexPath) {
        // Clear any spinner from a previously-resolving row and reset the pointer.
        // The async path re-sets it for the tapped row via willBeginResolving; a
        // cache hit resolves synchronously and leaves resolvingIndexPath nil, so a
        // stale pointer can't resurface the wrong spinner on reuse/reload.
        if let previous = resolvingIndexPath {
            (chaptersTable.cellForRow(at: previous) as? PlayerChapterCell)?.setResolving(false)
        }
        resolvingIndexPath = nil

        beginTrackingChapterSelection()

        GeneratedChapterSeeker.seek(
            to: chapter,
            startPlayback: true,
            willBeginResolving: { [weak self] in
                self?.resolvingIndexPath = indexPath
                (self?.chaptersTable.cellForRow(at: indexPath) as? PlayerChapterCell)?.setResolving(true)
            },
            didEndResolving: { [weak self] in
                self?.resolvingIndexPath = nil
                (self?.chaptersTable.cellForRow(at: indexPath) as? PlayerChapterCell)?.setResolving(false)
            },
            onSeek: { [weak self] targetTime in
                self?.chapterSelectionLatencyTracker.arm(targetTime: targetTime, targetDuration: chapter.duration)
            }
        )
    }

    /// Start measuring playback-start latency for the current chapter tap and
    /// fire `player_chapter_selected` once playback resumes (or times out with
    /// no latency). The event is deferred so it can carry the raw tap-to-playback
    /// `playback_start_latency_ms`, matching Android's `player_chapter_selected`
    /// (pocket-casts-android#5522).
    private func beginTrackingChapterSelection() {
        let episodeUuid = PlaybackManager.shared.currentEpisode()?.uuid ?? "unknown"
        let podcastUuid = PlaybackManager.shared.currentPodcast?.uuid ?? "unknown"

        chapterSelectionLatencyTracker.begin(tapDate: Date(), episodeUuid: episodeUuid) { latencyMs in
            Self.trackChapterSelected(episodeUuid: episodeUuid, podcastUuid: podcastUuid, latencyMs: latencyMs)
        }
    }

    /// The uuids are captured at tap time (as Android does) so a deferred event
    /// still reports the episode the chapter belonged to, even if the listener
    /// switches episodes before the latency resolves.
    func trackChapterSelected(latencyMs: Int?) {
        Self.trackChapterSelected(
            episodeUuid: PlaybackManager.shared.currentEpisode()?.uuid ?? "unknown",
            podcastUuid: PlaybackManager.shared.currentPodcast?.uuid ?? "unknown",
            latencyMs: latencyMs
        )
    }

    private static func trackChapterSelected(episodeUuid: String, podcastUuid: String, latencyMs: Int?) {
        var properties: [String: Any] = [
            "source": "fullscreen_player",
            "episode_uuid": episodeUuid,
            "podcast_uuid": podcastUuid
        ]
        if let latencyMs {
            properties["playback_start_latency_ms"] = latencyMs
        }
        PlaybackManager.shared.trackChapterEvent(.playerChapterSelected, properties: properties)
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
