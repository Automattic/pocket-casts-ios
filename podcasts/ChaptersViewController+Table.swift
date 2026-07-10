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
            } else if GeneratedChapterSeeker.isEnabled {
                resolveAndSeek(to: chapter, at: indexPath)
            } else {
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
                PlaybackManager.shared.trackChapterEvent(.playerChapterSelected)
            }
        }
    }

    private func resolveAndSeek(to chapter: ChapterInfo, at indexPath: IndexPath) {
        // Move the spinner to the tapped row (clearing any previous one).
        if let previous = resolvingIndexPath, previous != indexPath {
            (chaptersTable.cellForRow(at: previous) as? PlayerChapterCell)?.setResolving(false)
        }

        // Fire on every tap — including the cache hit that resolves synchronously
        // without a spinner — so the selection event matches the non-generated path.
        PlaybackManager.shared.trackChapterEvent(.playerChapterSelected)

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
            }
        )
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
