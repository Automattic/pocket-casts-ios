import Foundation
import UIKit

enum HapticsHelper {
    static func triggerSkipBackHaptic() {
        triggerImpactOccurredHaptic(style: .medium)
    }

    static func triggerSkipForwardHaptic() {
        triggerImpactOccurredHaptic(style: .medium)
    }

    static func triggerSubscribedHaptic() {
        triggerSuccessHaptic()
    }

    static func triggerStarHaptic() {
        triggerImpactOccurredHaptic(style: .light)
    }

    static func triggerPlayPauseHaptic() {
        triggerImpactOccurredHaptic(style: .light)
    }

    #if os(tvOS)
    enum FeedbackStyle {
        case heavy
        case light
        case medium
    }
    private static func triggerImpactOccurredHaptic(style: HapticsHelper.FeedbackStyle) {
        //No op
    }

    private static func triggerSuccessHaptic() {
        //No op
    }

    static func triggerErrorHaptic() {
        //No op
    }
    #else
    private static func triggerImpactOccurredHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator.impactOccurred()
    }

    private static func triggerSuccessHaptic() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
    }

    static func triggerErrorHaptic() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.error)
    }
    #endif
}
