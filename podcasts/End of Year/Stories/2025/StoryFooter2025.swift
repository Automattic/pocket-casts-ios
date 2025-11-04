import SwiftUI
import PocketCastsServer

struct StoryFooter2025: View {
    let title: String?
    let description: String?
    let subscriptionTier: SubscriptionTier?

    init(title: String? = nil, description: String? = nil, subscriptionTier: SubscriptionTier? = nil) {
        self.title = title
        self.description = description
        self.subscriptionTier = subscriptionTier
    }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack { Spacer() }
            if let subscriptionTier {
                SubscriptionBadge2024(subscriptionTier: subscriptionTier)
            }
            if let title {
                Text(title)
                    .font(.system(size: 31, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            if let description {
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}
