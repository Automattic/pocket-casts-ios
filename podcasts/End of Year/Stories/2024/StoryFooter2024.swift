import SwiftUI
import PocketCastsServer

struct StoryFooter2024: View {
    let title: String
    let description: String?
    let subscriptionTier: SubscriptionTier?

    init(title: String, description: String?, subscriptionTier: SubscriptionTier? = nil) {
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
                .font(.system(size: 31, weight: .bold))
            if let description {
                Text(description)
                    .font(.system(size: 15, weight: .light))
                    .lineSpacing(UIFont.systemFont(ofSize: 15, weight: .light).lineHeight*0.3)
            }
        }
        .minimumScaleFactor(0.9)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}
