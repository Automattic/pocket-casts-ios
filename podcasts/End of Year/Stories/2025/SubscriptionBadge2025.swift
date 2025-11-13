import SwiftUI
import PocketCastsServer

struct SubscriptionBadge2025: View {
    let subscriptionTier: SubscriptionTier

    var body: some View {
        switch subscriptionTier {
        case .patron:
            Image("playback-25-patron-badge")
        case .plus:
            Image("playback-25-plus-badge")
        default:
            EmptyView()
        }
    }
}
