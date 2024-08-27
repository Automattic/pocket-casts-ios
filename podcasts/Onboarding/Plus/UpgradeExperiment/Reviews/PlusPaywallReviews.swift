import SwiftUI
import PocketCastsServer

struct PlusPaywallReviews: View {
    let tier: UpgradeTier

    @Environment(\.openURL) private var openURL

    private var header: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("“\(L10n.upgradeExperimentReviewsTitle)”")
                .font(size: Constants.titleSize, style: .body, weight: .bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(L10n.upgradeExperimentReviewsText)
                .font(size: Constants.textSize, style: .body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Constants.textColor)
                .padding(.top, Constants.textTopPadding)
                .padding(.bottom, Constants.textBottomPadding)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, spacing: 0) {
                header
                PlusPaywallReviewsPlusFeatures(tier: tier)
                PlusPaywallReviewsStars()
                    .padding(.vertical, Constants.starsBottomPadding)
                VStack(spacing: 16.0) {
                    ForEach(PlusPaywallReview.reviews, id: \.id) { review in
                        PlusPaywallReviewCard(
                            review: PlusPaywallReview(
                                title: review.title,
                                review: review.review, date: review.date)
                        )
                    }
                }
                Button {
                    openURL(URL(string: ServerConstants.Urls.appStore)!)
                } label: {
                    Text("See all reviews in the App Store")
                        .font(size: 13.0, style: .body)
                        .foregroundStyle(Color(hex: "#FED443"))
                }
                .padding(.vertical, 32.0)

            }
            .padding(.horizontal, Constants.containerHPadding)
        }
        .background(.black)
    }

    private enum Constants {
        static let textColor = Color(hex: "#B8C3C9")
        static let containerHPadding = 20.0
        static let starsBottomPadding = 24.0
        static let titleSize = 22.0
        static let textSize = 14.0
        static let textTopPadding = 8.0
        static let textBottomPadding = 8.0
    }
}

#Preview {
    PlusPaywallReviews(tier: .plus)
}
