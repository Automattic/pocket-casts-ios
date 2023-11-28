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

        return abs(velocity.y) > abs(velocity.x)
    }

    @objc private func handlePullingUpGesture(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.began {
            aboutToDisplayFullScreenPlayer()
            rootViewController()?.view.isUserInteractionEnabled = false
            fullScreenPlayer?.view.isUserInteractionEnabled = false
            playerOpenState = .beingDragged
        } else if recognizer.state == UIGestureRecognizer.State.changed {
            let currentPoint = recognizer.translation(in: view.superview)

            moveWhileDragging(offsetFromTop: currentPoint.y)
            fullScreenPlayer?.view.moveTo(y: fullScreenPlayer!.view.bounds.height + currentPoint.y)
        } else if recognizer.state == UIGestureRecognizer.State.ended {
            rootViewController()?.view.isUserInteractionEnabled = true
            fullScreenPlayer?.view.isUserInteractionEnabled = true

            let endPoint = recognizer.translation(in: view)

            // didn't move far enough
            if abs(endPoint.y) < MiniPlayerViewController.minMoveAmount {
                if !FeatureFlag.newPlayerTransition.enabled {
                    closeFullScreenPlayer()
                }

                return
            }

            // the user has moved far enough
            openFullScreenPlayer()
        } else if recognizer.state == UIGestureRecognizer.State.cancelled {
            rootViewController()?.view.isUserInteractionEnabled = true
            fullScreenPlayer?.view.isUserInteractionEnabled = true

            closeFullScreenPlayer()
        }
    }

    @objc private func miniPlayerLongPressed(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.began {
            showLongPressMenu(recognizer.location(in: view.superview))
        }
    }

    private func showLongPressMenu(_ touchPoint: CGPoint) {
        Analytics.track(.miniPlayerLongPressMenuShown)

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

    @objc private func miniPlayerTapped() {
        openFullScreenPlayer()
    }
}
