import Foundation

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
        if playerOpenState != .open { view.isHidden = false }
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

        if playerOpenState == .open || playerOpenState == .animating { return }

        guard !FeatureFlag.newPlayerTransition.enabled else {
            playerOpenState = .animating
            aboutToDisplayFullScreenPlayer()

            fullScreenPlayer?.modalPresentationStyle = .overCurrentContext

            presentFromRootController(fullScreenPlayer!, animated: true) {
                self.playerOpenState = .open
                self.rootViewController()?.setNeedsStatusBarAppearanceUpdate()
                self.rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()
                AnalyticsHelper.nowPlayingOpened()
                completion?()
            }

            return
        }

        playerOpenState = .animating
        aboutToDisplayFullScreenPlayer()
        view.superview?.layoutIfNeeded()
        fullScreenPlayer?.beginAppearanceTransition(true, animated: true)
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.94, initialSpringVelocity: 0.7, options: UIView.AnimationOptions.curveEaseIn, animations: { () in
            self.moveToHiddenTopPosition()
            self.fullScreenPlayer?.view.moveTo(y: 0)
        }) { _ in
            self.fullScreenPlayer?.endAppearanceTransition()
            self.view.isHidden = true
            self.moveToHiddenTopPosition() // call this again in case the animation block wasn't called. It's ok to call this twice
            self.playerOpenState = .open
            self.rootViewController()?.setNeedsStatusBarAppearanceUpdate()
            self.rootViewController()?.setNeedsUpdateOfHomeIndicatorAutoHidden()
            AnalyticsHelper.nowPlayingOpened()
            completion?()
        }
    }

    func closeFullScreenPlayer(completion: (() -> Void)? = nil) {
        if playerOpenState == .closed || playerOpenState == .animating {
            completion?()

            return
        }

        guard !FeatureFlag.newPlayerTransition.enabled else {
            playerOpenState = .animating

            fullScreenPlayer?.dismiss(animated: true) {
                self.finishedWithFullScreenPlayer()
                self.playerOpenState = .closed
                completion?()
            }
            return
        }

        fullScreenPlayer?.beginAppearanceTransition(false, animated: true)
        playerOpenState = .animating
        DispatchQueue.main.async {
            guard let parentView = self.view.superview else { return }

            let isSomethingPlaying = PlaybackManager.shared.currentEpisode() != nil
            self.view.isHidden = !isSomethingPlaying
            let parentViewHeight = parentView.bounds.height
            self.view.superview?.layoutIfNeeded()
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: UIView.AnimationOptions.curveEaseIn, animations: { () in
                self.moveToShownPosition()
                self.fullScreenPlayer?.view.moveTo(y: parentViewHeight)
            }, completion: { _ in
                self.moveToShownPosition() // call this again in case the animation block wasn't called. It's ok to call this twice
                self.fullScreenPlayer?.endAppearanceTransition()

                self.finishedWithFullScreenPlayer()
                self.playerOpenState = .closed
                completion?()
            })
        }
    }

    func moveToHiddenTopPosition() {
        guard !FeatureFlag.newPlayerTransition.enabled else {
            return
        }

        guard let parentView = view.superview, let tabBar = rootViewController()?.tabBar else { return }

        view.transform = CGAffineTransform(translationX: 0, y: tabBar.bounds.height - parentView.bounds.height)
        view.superview?.layoutIfNeeded()
    }

    func moveWhileDragging(offsetFromTop: CGFloat) {
        guard !FeatureFlag.newPlayerTransition.enabled else {
            return
        }

        view.transform = CGAffineTransform.identity
        let tabBarHeight = rootViewController()?.tabBar.bounds.height ?? 0
        view.transform = offsetFromTop < -tabBarHeight ? CGAffineTransform(translationX: 0, y: offsetFromTop + tabBarHeight) : CGAffineTransform(translationX: 0, y: 0)
        view.superview?.layoutIfNeeded()
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
