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
            let currentChapters = PlaybackManager.shared.currentChapters()

            if chapter.index == currentChapters.index {
                state = PlaybackManager.shared.playing() ? .currentlyPlaying : .currentlyPaused
            } else if chapter.index > currentChapters.index {
                state = .future
            }

            chapterCell.populateFrom(chapter: chapter, playState: state, isChapterToggleEnabled: isTogglingChapters) { url in
                if UserDefaults.standard.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    self.present(SFSafariViewController(with: url), animated: true)
                }
            }

            chapterCell.seperatorView.isHidden = (chapter.index == PlaybackManager.shared.currentChapters().index - 1 || chapter.index == PlaybackManager.shared.currentChapters().index || (indexPath.row == PlaybackManager.shared.chapterCount() - 1))
        }

        return chapterCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard !isTogglingChapters else {
            (tableView.cellForRow(at: indexPath) as? PlayerChapterCell)?.toggleChapterTapped(self)
            return
        }

        if let chapter = PlaybackManager.shared.chapterAt(index: indexPath.row) {
            if chapter.index == PlaybackManager.shared.currentChapters().index {
                containerDelegate?.scrollToNowPlaying()
            } else {
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: true)
                Analytics.track(.playerChapterSelected)
            }
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        FeatureFlag.deselectChapters.enabled ? 38 : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        FeatureFlag.deselectChapters.enabled ? UITableView.automaticDimension : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let header = UIStackView()
        header.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)
        header.isLayoutMarginsRelativeArrangement = true
        header.axis = .horizontal
        header.backgroundColor = .black
        let label = UILabel()
        label.text = "X chapters"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .footnote)
        let button = UIButton()
        button.setTitle("Skip chapters", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.addTarget(self, action: #selector(toggleChapterSelection), for: .touchUpInside)
        header.addArrangedSubview(label)
        header.addArrangedSubview(button)
        view.addSubview(header)
        view.anchorToAllSidesOf(view: header)

        return header
    }

    @objc func toggleChapterSelection(sender: UIButton) {
        isTogglingChapters.toggle()
        chaptersTable.reloadData()
    }
}
