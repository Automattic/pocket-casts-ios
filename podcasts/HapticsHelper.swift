import Foundation

class HapticsHelper {
    class func triggerSkipBackHaptic() {
        triggerImpactOccurredHaptic(style: .medium)
    }

    class func triggerSkipForwardHaptic() {
        triggerImpactOccurredHaptic(style: .medium)
    }

    class func triggerSubscribedHaptic() {
        triggerSuccessHaptic()
    }

    class func triggerStarHaptic() {
        triggerImpactOccurredHaptic(style: .light)
    }

    class func triggerPlayPauseHaptic() {
        triggerImpactOccurredHaptic(style: .light)
    }

    class func triggerRearrangeHaptic() {
        triggerImpactOccurredHaptic(style: .light)
    }

    class func triggerPullToRefreshHaptic() {
        triggerImpactOccurredHaptic(style: .heavy)
    }

    private class func triggerImpactOccurredHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator.impactOccurred()
    }

    private class func triggerSuccessHaptic() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
    }
}
