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

        let shouldShowNotes = (playingEpisode is Episode)
        let shouldShowChapters = PlaybackManager.shared.chapterCount() > 0

        // check to see if the visible views are already configured correctly
        if shouldShowNotes == showingNotes, shouldShowChapters == showingChapters { return }

        mainScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        tabsView.currentTab = 0
        showNotesItem.removeFromParent()
        showNotesItem.view.removeFromSuperview()
        showingNotes = false

        chaptersItem.removeFromParent()
        chaptersItem.view.removeFromSuperview()
        showingChapters = false

        tabsView.tabs = [.nowPlaying]

        if shouldShowNotes {
            showingNotes = true
            showNotesItem.willBeAddedToPlayer()
            mainScrollView.addSubview(showNotesItem.view)
            addChild(showNotesItem)

            finalScrollViewConstraint?.isActive = false
            let finalConstraint = showNotesItem.view.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor)
            NSLayoutConstraint.activate([
                showNotesItem.view.leadingAnchor.constraint(equalTo: nowPlayingItem.view.trailingAnchor),
                showNotesItem.view.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
                showNotesItem.view.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
                showNotesItem.view.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
                showNotesItem.view.heightAnchor.constraint(equalTo: mainScrollView.heightAnchor),
                finalConstraint
            ])
            finalScrollViewConstraint = finalConstraint

            tabsView.tabs += [.showNotes]
        }

        if shouldShowChapters {
            showingChapters = true
            chaptersItem.willBeAddedToPlayer()
            mainScrollView.addSubview(chaptersItem.view)
            addChild(chaptersItem)

            finalScrollViewConstraint?.isActive = false
            let finalConstraint = chaptersItem.view.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor)
            NSLayoutConstraint.activate([
                chaptersItem.view.leadingAnchor.constraint(equalTo: showingNotes ? showNotesItem.view.trailingAnchor : nowPlayingItem.view.trailingAnchor),
                chaptersItem.view.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
                chaptersItem.view.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
                chaptersItem.view.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
                chaptersItem.view.heightAnchor.constraint(equalTo: mainScrollView.heightAnchor),
                finalConstraint
            ])
            finalScrollViewConstraint = finalConstraint

            tabsView.tabs += [.chapters]
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
