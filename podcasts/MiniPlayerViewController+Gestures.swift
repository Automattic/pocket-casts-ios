import Foundation
import PocketCastsUtils

extension MiniPlayerViewController: UIGestureRecognizerDelegate {
    private static let minMoveAmount = 80 as CGFloat

    func addGestureRecognizers() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(miniPlayerLongPressed(_:)))
        longPressRecognizer.delegate = self
        view.addGestureRecognizer(longPressRecognizer)

        panUpRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePullingUpGesture(_:)))
        panUpRecognizer.delegate = self
        view.addGestureRecognizer(panUpRecognizer)

        let miniPlayerTap = UITapGestureRecognizer(target: self, action: #selector(miniPlayerTapped))
        miniPlayerTap.require(toFail: panUpRecognizer)
        miniPlayerTap.require(toFail: longPressRecognizer)
        view.addGestureRecognizer(miniPlayerTap)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != panUpRecognizer { return true }

        if playerOpenState == .animating { return false } // don't allow dragging until the player has finished an existing animation

        let velocity = panUpRecognizer.velocity(in: view)

        // Only recognize upward swipes (negative y velocity)
        return velocity.y < 0 && abs(velocity.y) > abs(velocity.x)
    }

    @objc private func handlePullingUpGesture(_ recognizer: UIPanGestureRecognizer) {
        // Open the full screen player as soon as the upward swipe is recognized,
        // rather than waiting for the gesture to end. This makes the transition
        // feel immediate and responsive.
        if recognizer.state == .began {
            openFullScreenPlayer()
        }
    }

    @objc private func miniPlayerLongPressed(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.began {
            showLongPressMenu(recognizer.location(in: view.superview))
        }
    }

    private func showLongPressMenu(_ touchPoint: CGPoint) {
        Analytics.track(.miniPlayerLongPressMenuShown)

        if FeatureFlag.liquidGlass.enabled {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.markPlayed, style: .default) { [weak self] _ in
                Analytics.track(.miniPlayerLongPressMenuOptionTapped, properties: ["option": "mark_played"])
                if let episode = PlaybackManager.shared.currentEpisode() {
                    guard let self else { return }
                    AnalyticsEpisodeHelper.shared.currentSource = self.analyticsSource
                    EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
                }
            })
            alert.addAction(UIAlertAction(title: L10n.miniPlayerClose, style: .destructive) { [weak self] _ in
                Analytics.track(.miniPlayerLongPressMenuOptionTapped, properties: ["option": "close_and_clear_up_next"])
                FileLog.shared.addMessage("Close and Clear Up Next pressed from the mini player")
                self?.removeAllCustomObservers()
                self?.hideMiniPlayer(true)
                PlaybackManager.shared.endPlayback()
                self?.addUINotificationObservers()
            })
            alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
                Analytics.track(.miniPlayerLongPressMenuDismissed)
            })
            present(alert, animated: true)
        } else {
            let optionsPicker = OptionsPicker(title: nil)
            let markAsPlayedAction = OptionAction(label: L10n.markPlayedShort, icon: "episode-markasplayed") {
                Analytics.track(.miniPlayerLongPressMenuOptionTapped, properties: ["option": "mark_played"])
                if let episode = PlaybackManager.shared.currentEpisode() {
                    AnalyticsEpisodeHelper.shared.currentSource = self.analyticsSource
                    EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
                }
            }
            optionsPicker.addAction(action: markAsPlayedAction)

            let closeAction = OptionAction(label: L10n.miniPlayerClose, icon: "close") {
                Analytics.track(.miniPlayerLongPressMenuOptionTapped, properties: ["option": "close_and_clear_up_next"])
                FileLog.shared.addMessage("Close and Clear Up Next pressed from the mini player")
                self.removeAllCustomObservers()
                self.hideMiniPlayer(true)
                PlaybackManager.shared.endPlayback()
                self.addUINotificationObservers()
            }
            closeAction.destructive = true
            optionsPicker.addAction(action: closeAction)

            optionsPicker.setNoActionCallback {
                Analytics.track(.miniPlayerLongPressMenuDismissed)
            }
            optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
        }
    }

    @objc private func miniPlayerTapped() {
        openFullScreenPlayer()
    }
}
