import Foundation
import PocketCastsUtils

extension MiniPlayerViewController {
    /// - parameter isTransient: If enabled, hiding temporarily with an intention to
    /// quickly show it again later.
    func hideMiniPlayer(_ animated: Bool, isTransient: Bool = false) {
        if LiquidGlass.isEnabled, #available(iOS 26, *) {
            guard let tabBarController = parent as? UITabBarController, tabBarController.bottomAccessory != nil else { return }
            tabBarController.setBottomAccessory(nil, animated: animated)
            if !isTransient {
                tabBarController.tabBarMinimizeBehavior = .never
            }
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.miniPlayerDidDisappear)
            return
        }

        if !miniPlayerShowing() { return } // already hidden

        if animated {
            view.superview?.layoutIfNeeded()
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: { () in
                self.moveToHiddenBottomPosition()
            }, completion: { _ in
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.miniPlayerDidDisappear)
                self.view.isHidden = true
            })
        } else {
            moveToHiddenBottomPosition()
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.miniPlayerDidDisappear)
            view.isHidden = true
        }
    }

    func showMiniPlayer() {
        // only show if something is playing
        if PlaybackManager.shared.currentEpisode == nil { return }

        if LiquidGlass.isEnabled, #available(iOS 26.0, *) {
            guard let tabBarController = parent as? UITabBarController, tabBarController.bottomAccessory == nil else { return }
            let accessory = UITabAccessory(contentView: view)
            tabBarController.tabBarMinimizeBehavior = Settings.tabBarMinimizingEnabled ? .onScrollDown : .never
            tabBarController.setBottomAccessory(accessory, animated: true)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.miniPlayerDidAppear)
            return
        }

        if miniPlayerShowing() { return }

        changeHeightTo(desiredHeight())
        moveToHiddenBottomPosition()
        self.view.isHidden = false
        view.superview?.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: { () in
            self.moveToShownPosition()
        }, completion: { _ in
            self.moveToShownPosition() // call this again in case the animation block wasn't called. It's ok to call this twice
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.miniPlayerDidAppear)
        })
    }

    func openFullScreenPlayer(completion: (() -> Void)? = nil) {
        guard PlaybackManager.shared.currentEpisode != nil else { return }

        if fullScreenPlayer?.presentingViewController != nil || fullScreenPlayer?.isBeingPresented == true { return }

        aboutToDisplayFullScreenPlayer()

        fullScreenPlayer?.modalPresentationStyle = .custom
        fullScreenPlayer?.transitioningDelegate = self

        guard let fullScreenPlayer else {
            return
        }

        fullScreenPlayer.nowPlayingItem.placeholderArtwork = podcastArtwork.imageView?.image

        guard let rootController = SceneHelper.rootViewController(includeTopMost: false) else {
            return
        }

        playerOpenState = .animating

        // UIKit ignores presentations started from a dismissing controller (e.g. the episode
        // card dismissing itself when Play is tapped), so present from the root instead.
        if rootController.presentedViewController != nil {
            rootController.dismiss(animated: true)
        }

        rootController.present(fullScreenPlayer, animated: true) {
            self.playerOpenState = .open
            self.rootViewController()?.setNeedsStatusBarAppearanceUpdate()
            self.rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()
            AnalyticsHelper.nowPlayingOpened()
            Analytics.track(.playerShown)
            completion?()
        }
    }

    func closeFullScreenPlayer(completion: (() -> Void)? = nil) {
        if fullScreenPlayer?.presentingViewController == nil || fullScreenPlayer?.isBeingDismissed == true {
            completion?()

            return
        }

        playerOpenState = .animating

        rootViewController()?.dismiss(animated: true) {
            self.finishedWithFullScreenPlayer()
            self.playerOpenState = .closed
            Analytics.track(.playerDismissed)
            completion?()
        }
    }

    private func moveToHiddenBottomPosition() {
        view.transform = CGAffineTransform(translationX: 0, y: desiredHeight())
        view.superview?.layoutIfNeeded()
    }

    private func moveToShownPosition() {
        view.transform = .identity
        view.superview?.layoutIfNeeded()
    }

    /// Re-applies `tabBarMinimizeBehavior` from the current `Settings.tabBarMinimizingEnabled`
    /// so a toggle flip in Appearance takes effect right away while the mini player is showing.
    func applyTabBarMinimizingPreference() {
        guard LiquidGlass.isEnabled, #available(iOS 26.0, *) else { return }
        guard let tabBarController = parent as? UITabBarController, tabBarController.bottomAccessory != nil else { return }
        tabBarController.tabBarMinimizeBehavior = Settings.tabBarMinimizingEnabled ? .onScrollDown : .never
    }

    func closeUpNextAndFullPlayer(completion: (() -> Void)? = nil) {
        if fullScreenPlayer != nil {
            closeFullScreenPlayer(completion: {
                completion?()
            })
            return
        }

        if let upNextViewController {
            upNextViewController.dismiss(animated: true, completion: nil)
        }
        completion?()
    }
}
