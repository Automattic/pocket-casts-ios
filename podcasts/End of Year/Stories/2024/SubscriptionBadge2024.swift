import SwiftUI
import PocketCastsServer

struct SubscriptionBadge2024: View {
    let subscriptionTier: SubscriptionTier

    var body: some View {
        switch subscriptionTier {
        case .patron:
            Image("playback-24-patron-badge")
        case .plus:
            Image("playback-24-plus-badge")
        default:
            EmptyView()
        }
    }
}
