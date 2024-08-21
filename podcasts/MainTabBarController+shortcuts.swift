import Foundation
import PocketCastsUtils

extension MainTabBarController {
    func setupKeyboardShortcuts() {
        // playback
        addKeyCommand(playPauseCommand)

        let skipBackCommand = UIKeyCommand(title: L10n.skipBack, action: #selector(handleSkipBack), input: UIKeyCommand.inputLeftArrow, modifierFlags: [.command])
        addKeyCommand(skipBackCommand)

        let skipForwardCommand = UIKeyCommand(title: L10n.skipForward, action: #selector(handleSkipForward), input: UIKeyCommand.inputRightArrow, modifierFlags: [.command])
        addKeyCommand(skipForwardCommand)

        let openPlayerCommand = UIKeyCommand(title: L10n.keycommandOpenPlayer, action: #selector(handleOpenPlayer), input: UIKeyCommand.inputUpArrow, modifierFlags: [.command])
        addKeyCommand(openPlayerCommand)

        let closePlayerCommand = UIKeyCommand(title: L10n.keycommandClosePlayer, action: #selector(handleClosePlayer), input: UIKeyCommand.inputDownArrow, modifierFlags: [.command])
        addKeyCommand(closePlayerCommand)

        let decreaseSpeedCommand = UIKeyCommand(title: L10n.keycommandDecreaseSpeed, action: #selector(handleDecreaseSpeed), input: "[", modifierFlags: [.command])
        addKeyCommand(decreaseSpeedCommand)

        let increaseSpeedCommand = UIKeyCommand(title: L10n.keycommandIncreaseSpeed, action: #selector(handleIncreaseSpeed), input: "]", modifierFlags: [.command])
        addKeyCommand(increaseSpeedCommand)

        // navigation
        let podcastsCommand = UIKeyCommand(title: L10n.podcastsPlural, action: #selector(handlePodcasts), input: "1", modifierFlags: [.command])
        addKeyCommand(podcastsCommand)

        let filtersCommand = UIKeyCommand(title: L10n.filters, action: #selector(handleFilters), input: "2", modifierFlags: [.command])
        addKeyCommand(filtersCommand)

        let discoverCommand = UIKeyCommand(title: L10n.discover, action: #selector(handleDiscover), input: "3", modifierFlags: [.command])
        addKeyCommand(discoverCommand)

        // If the feature flag is enabled then Up Next is in position 4 and Profile in position 5 on the tab bar.
        // If disabled, then Profile remains in the original position 4. Set the keyboard shortcuts accordingly.
        if FeatureFlag.upNextOnTabBar.enabled {
            let upNextCommand = UIKeyCommand(title: L10n.upNext, action: #selector(handleUpNext), input: "4", modifierFlags: [.command])
            addKeyCommand(upNextCommand)

            let profileCommand = UIKeyCommand(title: L10n.profile, action: #selector(handleProfile), input: "5", modifierFlags: [.command])
            addKeyCommand(profileCommand)
        } else {
            let profileCommand = UIKeyCommand(title: L10n.profile, action: #selector(handleProfile), input: "4", modifierFlags: [.command])
            addKeyCommand(profileCommand)
        }

        let searchCommand = UIKeyCommand(title: L10n.search, action: #selector(handleSearch), input: "f", modifierFlags: [.command])
        addKeyCommand(searchCommand)
    }

    @objc func handleSearch() {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.searchRequested, object: nil)
    }

    @objc func handlePlayPauseKey() {
        PlaybackManager.shared.playPause()
    }

    @objc private func handleSkipBack() {
        PlaybackManager.shared.skipBack()
    }

    @objc private func handleSkipForward() {
        PlaybackManager.shared.skipForward()
    }

    @objc private func handlePodcasts() {
        navigateToPodcastList(true)
    }

    @objc private func handleFilters() {
        navigateToFilterTab()
    }

    @objc private func handleDiscover() {
        navigateToDiscover(true)
    }

    @objc private func handleUpNext() {
        navigateToUpNext(true)
    }

    @objc private func handleProfile() {
        navigateToProfile(true)
    }

    @objc private func handleDecreaseSpeed() {
        PlaybackManager.shared.decreasePlaybackSpeed()
    }

    @objc private func handleIncreaseSpeed() {
        PlaybackManager.shared.increasePlaybackSpeed()
    }

    @objc private func handleOpenPlayer() {
        NavigationManager.sharedManager.miniPlayer?.openFullScreenPlayer()
    }

    @objc private func handleClosePlayer() {
        NavigationManager.sharedManager.miniPlayer?.closeFullScreenPlayer()
    }

    @objc func textEditingDidStart() {
        removeKeyCommand(playPauseCommand)
    }

    @objc func textEditingDidEnd() {
        addKeyCommand(playPauseCommand)
    }
}
