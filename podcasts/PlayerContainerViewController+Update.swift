import Foundation
import PocketCastsDataModel

extension PlayerContainerViewController {
    func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
    }

    @objc func update() {
        guard PlaybackManager.shared.currentEpisode() != nil else {
            closeNowPlaying()

            return
        }

        updateColors()
        updateAvailableTabs()
    }

    private func updateAvailableTabs() {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return }

        // Update the colors when the episode changes
        tabsView.themeDidChange()

        let shouldShowNotes = (playingEpisode is Episode)
        let shouldShowChapters = PlaybackManager.shared.chapterCount() > 0
        let shouldShowBookmarks = true

        // check to see if the visible views are already configured correctly
        if shouldShowNotes == showingNotes,
            shouldShowChapters == showingChapters,
            shouldShowBookmarks == showingBookmarks {
            return
        }

        mainScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        tabsView.currentTab = 0
        showNotesItem.removeFromParent()
        showNotesItem.view.removeFromSuperview()
        showingNotes = false

        chaptersItem.removeFromParent()
        chaptersItem.view.removeFromSuperview()
        showingChapters = false

        bookmarksItem.removeFromParent()
        bookmarksItem.view.removeFromSuperview()
        showingBookmarks = false

        tabsView.tabs = [.nowPlaying]

        var previousTab: PlayerItemViewController = nowPlayingItem

        if shouldShowNotes {
            showingNotes = true
            tabsView.tabs += [.showNotes]

            addTab(showNotesItem, previousTab: &previousTab)
        }

        if shouldShowChapters {
            showingChapters = true
            tabsView.tabs += [.chapters]

            addTab(chaptersItem, previousTab: &previousTab)
        }

        if shouldShowBookmarks {
            showingBookmarks = true
            tabsView.tabs += [.bookmarks]

            addTab(bookmarksItem, previousTab: &previousTab)
        }
    }

    private func addTab(_ tab: PlayerItemViewController, previousTab: inout PlayerItemViewController) {
        guard addTab(tab, after: previousTab) else { return }

        previousTab = tab
    }

    @discardableResult
    func addTab(_ tab: PlayerItemViewController, after afterTab: PlayerItemViewController? = nil) -> Bool {
        guard let tabView = tab.view else { return false }

        tab.willBeAddedToPlayer()
        mainScrollView.addSubview(tabView)
        addChild(tab)

        let previousAnchor = afterTab?.view.map { $0.trailingAnchor } ?? mainScrollView.leadingAnchor

        finalScrollViewConstraint?.isActive = false
        let finalConstraint = tab.view.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor)
        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: previousAnchor),
            tabView.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            tabView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            tabView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
            tabView.heightAnchor.constraint(equalTo: mainScrollView.heightAnchor),
            finalConstraint
        ])

        finalScrollViewConstraint = finalConstraint
        return true
    }
}
