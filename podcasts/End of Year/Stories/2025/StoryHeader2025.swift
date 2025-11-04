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
            if let subscriptionTier {
                SubscriptionBadge2025(subscriptionTier: subscriptionTier)
                    .padding(.bottom, 8)
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
        .padding(.horizontal, 24)
        .padding(.top, UIScreen.isSmallScreen ? 80 : 110)
    }
}

struct StoryHeader2025_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StoryHeader2025(title: "This is the title")
            StoryHeader2025(title: "This is the title", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
            StoryHeader2025(title: "This is the title", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", subscriptionTier: .plus)
            StoryHeader2025(title: "This is the title", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", subscriptionTier: .patron)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
