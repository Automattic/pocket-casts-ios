import Foundation
import PocketCastsUtils

extension MiniPlayerViewController: UIGestureRecognizerDelegate {
    private static let minMoveAmount = 80 as CGFloat

    func addGestureRecognizers() {
        panUpRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePullingUpGesture(_:)))
        panUpRecognizer.delegate = self
        view.addGestureRecognizer(panUpRecognizer)

        let miniPlayerTap = UITapGestureRecognizer(target: self, action: #selector(miniPlayerTapped))
        miniPlayerTap.require(toFail: panUpRecognizer)

        if LiquidGlass.isEnabled {
            view.addInteraction(UIContextMenuInteraction(delegate: self))
        } else {
            longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(miniPlayerLongPressed(_:)))
            longPressRecognizer.delegate = self
            view.addGestureRecognizer(longPressRecognizer)
            miniPlayerTap.require(toFail: longPressRecognizer)
        }

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
            // Recognizer y-velocity is negative for an upward flick; pass it
            // through verbatim so the present spring carries the gesture's
            // momentum (and a fast flick shortens the duration).
            pendingPresentVelocity = recognizer.velocity(in: view).y
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

        let optionsPicker = OptionsPicker(title: nil)
        for action in longPressMenuActions() {
            optionsPicker.addAction(action: action)
        }
        optionsPicker.setNoActionCallback {
            Analytics.track(.miniPlayerLongPressMenuDismissed)
        }

        optionsPicker.present()
    }

    @objc private func miniPlayerTapped() {
        openFullScreenPlayer()
    }

    /// Shared action list used by both the legacy `OptionsPicker` long-press
    /// menu and the Liquid Glass `UIContextMenuInteraction`. Each action's
    /// closure includes its own analytics event so both menu styles produce
    /// the same telemetry.
    fileprivate func longPressMenuActions() -> [OptionAction] {
        let markAsPlayed = OptionAction(label: L10n.markPlayedShort, icon: "episode-markasplayed") { [weak self] in
            guard let self else { return }
            Analytics.track(.miniPlayerLongPressMenuOptionTapped, properties: ["option": "mark_played"])
            if let episode = PlaybackManager.shared.currentEpisode {
                AnalyticsEpisodeHelper.shared.currentSource = self.analyticsSource
                EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
            }
        }

        let close = OptionAction(label: L10n.miniPlayerClose, icon: "close") { [weak self] in
            guard let self else { return }
            Analytics.track(.miniPlayerLongPressMenuOptionTapped, properties: ["option": "close_and_clear_up_next"])
            FileLog.shared.addMessage("Close and Clear Up Next pressed from the mini player")
            self.removeAllCustomObservers()
            self.hideMiniPlayer(true)
            PlaybackManager.shared.endPlayback()
            self.addUINotificationObservers()
        }
        close.destructive = true

        return [markAsPlayed, close]
    }
}

extension MiniPlayerViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        Analytics.track(.miniPlayerLongPressMenuShown)
        longPressContextMenuActionSelected = false
        let actions = longPressMenuActions()

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                guard let episode = PlaybackManager.shared.currentEpisode else { return nil }
                return MiniPlayerLongPressPreviewViewController(episode: episode)
            },
            actionProvider: { [weak self] _ in
                UIMenu(children: actions.map { action in
                    UIAction(
                        title: action.label,
                        image: action.icon.flatMap { UIImage(named: $0) },
                        attributes: action.destructive ? .destructive : []
                    ) { _ in
                        self?.longPressContextMenuActionSelected = true
                        action.action()
                    }
                })
            }
        )
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        if !longPressContextMenuActionSelected {
            Analytics.track(.miniPlayerLongPressMenuDismissed)
        }
    }
}
