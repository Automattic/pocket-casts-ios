import SwiftUI

struct PlusPaywallReviewsPlusFeatures: View {
    let tier: UpgradeTier

    private var badge: some View {
        HStack {
            Spacer()
            SubscriptionBadge(tier: tier.tier, displayMode: .gradient, foregroundColor: .black)
            Spacer()
        }
    }

    private var gradientStroke: some View {
        Rectangle()
            .foregroundColor(.clear)
            .cornerRadius(Constants.backgroundCorner)
            .padding(.top, Constants.backgroundTopPadding)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.backgroundCorner)
                    .stroke(Color.plusGradient, lineWidth: Constants.backgroundStroke)
                    .padding(.top, Constants.backgroundTopPadding)
            )
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Constants.vStackSpacing) {
            ForEach(tier.yearlyFeatures, id: \.self) { feature in
                HStack(spacing: Constants.hStackSpacing) {
                    Image(feature.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                    UnderlineLinkTextView(feature.title)
                        .font(size: Constants.textSize, style: .subheadline, weight: .medium)
                        .foregroundColor(.white)
                        .tint(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.horizontal, Constants.featuresPaddingH)
            }
        }
        .padding(.top, Constants.featuresPaddingTop)
        .padding(.bottom, Constants.featuresPaddingH)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            gradientStroke
            VStack(spacing: 0) {
                badge
                features
            }
        }
    }

    enum Constants {
        static let backgroundCorner = 10.0
        static let backgroundTopPadding = 16.0
        static let backgroundStroke = 3.0
        static let featuresPaddingH = 32.0
        static let featuresPaddingTop = 20.0
        static let vStackSpacing = 12.0
        static let hStackSpacing = 20.0
        static let imageSize = CGSize(width: 16.0, height: 16.0)
        static let textSize = 14.0
    }
}

#Preview {
    VStack {
        PlusPaywallReviewsPlusFeatures(tier: .plus)
        Spacer()
    }
    .padding(20.0)
    .background(.black)
}
