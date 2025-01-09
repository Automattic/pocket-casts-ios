import Foundation
import PocketCastsUtils

extension MiniPlayerViewController {
    func hideMiniPlayer(_ animated: Bool) {
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
        if miniPlayerShowing() { return }

        // only show if something is playing
        if PlaybackManager.shared.currentEpisode() == nil { return }

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
        guard PlaybackManager.shared.currentEpisode() != nil else { return }

        if fullScreenPlayer?.presentingViewController != nil || fullScreenPlayer?.isBeingPresented == true { return }

        aboutToDisplayFullScreenPlayer()

        fullScreenPlayer?.modalPresentationStyle = .custom
        fullScreenPlayer?.transitioningDelegate = self

        guard let fullScreenPlayer else {
            return
        }

        playerOpenState = .animating

        presentFromRootController(fullScreenPlayer, animated: true) {
            self.playerOpenState = .open
            self.rootViewController()?.setNeedsStatusBarAppearanceUpdate()
            self.rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()
            AnalyticsHelper.nowPlayingOpened()
            Analytics.track(.playerShown)
            completion?()
        } failure: {
            self.playerOpenState = .closed
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

    func closeUpNextAndFullPlayer(completion: (() -> Void)? = nil) {
        if let fullScreenPlayer = fullScreenPlayer {
            _ = fullScreenPlayer.children.map { $0.dismiss(animated: false, completion: nil) }
            closeFullScreenPlayer(completion: {
                completion?()
            })
            return
        }

        if let upNextViewController = upNextViewController {
            upNextViewController.dismiss(animated: true, completion: nil)
        }
        completion?()
    }
}
