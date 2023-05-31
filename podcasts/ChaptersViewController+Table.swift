import Foundation
import SafariServices

extension ChaptersViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    private static let chapterCell = "ChapterCell"

    func registerCells() {
        chaptersTable.register(UINib(nibName: "PlayerChapterCell", bundle: nil), forCellReuseIdentifier: ChaptersViewController.chapterCell)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewHandler?.scrollViewDidScroll?(scrollView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PlaybackManager.shared.chapterCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chapterCell = tableView.dequeueReusableCell(withIdentifier: ChaptersViewController.chapterCell, for: indexPath) as! PlayerChapterCell

        if let chapter = PlaybackManager.shared.chapterAt(index: indexPath.row) {
            var state = PlayerChapterCell.ChapterPlayState.played
            if let currentChapter = PlaybackManager.shared.currentChapter() {
                if chapter.index == currentChapter.index {
                    state = PlaybackManager.shared.playing() ? .currentlyPlaying : .currentlyPaused
                } else if chapter.index > currentChapter.index {
                    state = .future
                }
            }

            chapterCell.populateFrom(chapter: chapter, playState: state) { url in
                if UserDefaults.standard.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    self.present(SFSafariViewController(with: url), animated: true)
                }
            }

            chapterCell.seperatorView.isHidden = (chapter.index == (PlaybackManager.shared.currentChapter()?.index ?? 0) - 1 || chapter.index == (PlaybackManager.shared.currentChapter()?.index ?? 0) || (indexPath.row == PlaybackManager.shared.chapterCount() - 1))
        }

        return chapterCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let chapter = PlaybackManager.shared.chapterAt(index: indexPath.row) {
            if chapter.index == PlaybackManager.shared.currentChapter()?.index {
                containerDelegate?.scrollToNowPlaying()
            } else {
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
                Analytics.track(.playerChapterSelected)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNonzeroMagnitude
    }
}
