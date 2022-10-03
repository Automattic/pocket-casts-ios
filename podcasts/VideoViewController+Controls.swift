
extension VideoViewController {
    private static let controlHideTime = 3.seconds

    @objc func videoViewTapped() {
        if controlsDisabled { return }

        toggleVideoControls()
    }

    @objc func videoViewDoubleTapped() {
        if controlsDisabled { return }

        toggleFillScreen()
    }

    // MARK: - Timer

    func startHideControlsTimer() {
        if controlsDisabled { return }

        stopHideControlsTimer()

        showHideTimer = Timer.scheduledTimer(withTimeInterval: VideoViewController.controlHideTime, repeats: false, block: { [weak self] _ in
            self?.hideVideoControls()
        })
    }

    func stopHideControlsTimer() {
        showHideTimer?.invalidate()
    }

    // MARK: - Hide Show

    func disableControls() {
        controlsDisabled = true
        hideVideoControls()
    }

    func enableControls() {
        controlsDisabled = false
        showVideoControls()
    }

    private func toggleVideoControls() {
        if controlsShowing {
            hideVideoControls()
        } else {
            showVideoControls()
            if PlaybackManager.shared.playing() { startHideControlsTimer() }
        }
    }

    private func hideVideoControls() {
        controlsShowing = false
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) { [weak self] in
            self?.controlsOverlay.alpha = 0
        }
    }

    private func showVideoControls() {
        controlsShowing = true
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) { [weak self] in
            self?.controlsOverlay.alpha = 1
        }
    }
}
