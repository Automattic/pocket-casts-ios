import SwiftUI
import PocketCastsServer

struct StoryHeader2025: View {
    let title: String?
    let description: String?
    let subscriptionTier: SubscriptionTier?
    let addTopPadding: Bool

    init(title: String? = nil, description: String? = nil, subscriptionTier: SubscriptionTier? = nil, addTopPadding: Bool = true) {
        self.title = title
        self.description = description
        self.subscriptionTier = subscriptionTier
        self.addTopPadding = addTopPadding
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
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
        .if(addTopPadding) { content in
            content.padding(.top, UIScreen.isSmallScreen ? 80 : 110)
        }
    }
}
