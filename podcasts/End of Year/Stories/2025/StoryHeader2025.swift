import SwiftUI
import PocketCastsServer

struct StoryHeader2025: View {
    let title: String?
    let description: String?
    let subscriptionTier: SubscriptionTier?

    init(title: String? = nil, description: String? = nil, subscriptionTier: SubscriptionTier? = nil) {
        self.title = title
        self.description = description
        self.subscriptionTier = subscriptionTier
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack { Spacer() }
            if let subscriptionTier {
                SubscriptionBadge2024(subscriptionTier: subscriptionTier)
            }
            if let title {
                Text(title)
                    .font(size: 25, style: .title, weight: .semibold)
                    .multilineTextAlignment(.center)
            }
            if let description {
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
            }
        }
        .minimumScaleFactor(0.9)
        .padding(.horizontal, 24)
        .padding(.top, 110)
    }
}
