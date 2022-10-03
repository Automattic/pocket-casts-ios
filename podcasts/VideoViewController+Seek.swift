
extension VideoViewController: TimeSliderDelegate {
    func sliderDidBeginSliding() {}
    func sliderDidEndSliding() {}

    func sliderDidProvisionallySlide(to time: TimeInterval) {
        if PlaybackManager.shared.playing() { startHideControlsTimer() }

        updateUpTo(upTo: time, duration: PlaybackManager.shared.duration(), moveSlider: false)
    }

    func sliderDidSlide(to time: TimeInterval) {
        PlaybackManager.shared.seekTo(time: time)
    }
}
