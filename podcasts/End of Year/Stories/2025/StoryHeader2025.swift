import SwiftUI
import PocketCastsServer

struct StoryHeader2025: View {
    let title: String
    let description: String?
    let subscriptionTier: SubscriptionTier?

    init(title: String, description: String? = nil, subscriptionTier: SubscriptionTier? = nil) {
        self.title = title
        self.description = description
        self.subscriptionTier = subscriptionTier
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Spacer() }
            if let subscriptionTier {
                SubscriptionBadge2024(subscriptionTier: subscriptionTier)
            }
            Text(title)
                .font(size: 25, style: .title, weight: .semibold)
                .multilineTextAlignment(.center)
            if let description {
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .lineSpacing(UIFont.systemFont(ofSize: 16, weight: .medium).lineHeight*1.09)
                    .multilineTextAlignment(.center)
            }
        }
        .minimumScaleFactor(0.9)
        .padding(.horizontal, 24)
        .padding(.top, UIScreen.isSmallScreen ? 80 : 110)
    }
}
