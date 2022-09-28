import UIKit

extension NowPlayingPlayerItemViewController: TimeSliderDelegate {
    func sliderDidBeginSliding() {
        if PlaybackManager.shared.chapterCount() == 0 {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: { () in
                self.podcastName.alpha = 0
            })
        }
    }

    func sliderDidEndSliding() {
        if PlaybackManager.shared.chapterCount() == 0 {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: { () in
                self.podcastName.alpha = 1
            })
        }
    }

    func sliderDidProvisionallySlide(to time: TimeInterval) {
        updateUpTo(upTo: time, duration: PlaybackManager.shared.duration(), moveSlider: false)
        updateProvisionalChapterInfoForTime(time: time)
    }

    func sliderDidSlide(to time: TimeInterval) {
        PlaybackManager.shared.seekTo(time: time)
    }
}
