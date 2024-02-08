import SwiftUI

/// View to display the price of a subscription and any offer associated.
struct SubscriptionPriceAndOfferView: View {

    typealias ProductInfo = PlusPricingInfoModel.PlusProductPricingInfo

    private let product: ProductInfo
    private let mainTextColor: Color
    private let secondaryTextColor: Color

    init(product: ProductInfo, mainTextColor: Color, secondaryTextColor: Color) {
        self.product = product
        self.mainTextColor = mainTextColor
        self.secondaryTextColor = secondaryTextColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            OfferStack {
                SubscriptionBadge(tier: product.identifier.subscriptionTier)

                if let offerDescription = offerDescription(for: product) {
                    Text(offerDescription)
                        .foregroundColor(product.identifier.plan == .plus ? Color.black : Color.white)
                        .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                        .background(product.identifier.plan == .plus ? Color.plusBackgroundColor2 : Color.patronBackgroundColor)
                        .textCase(.uppercase)
                        .font(style: .caption2, weight: .semibold)
                        .clipShape(.capsule)
                }
            }

            Text(price(for: product))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
    }

    private func price(for subscriptionInfo: ProductInfo) -> AttributedString {
        let subscriptionPeriod = subscriptionInfo.identifier.productInfo.frequency.description

        let priceFont = UIFont.font(with: .headline, maxSizeCategory: .accessibilityExtraLarge)
        let periodFont = UIFont.font(with: .footnote, maxSizeCategory: .accessibilityExtraLarge)

        // Only show the offer price for the intro discount
        guard let offer = subscriptionInfo.offer, offer.type == .discount else {
            var basePrice =  AttributedString(subscriptionInfo.rawPrice)
            basePrice.font = priceFont
            basePrice.foregroundColor = mainTextColor

            var basePeriod = AttributedString("/ \(subscriptionPeriod)")
            basePeriod.foregroundColor = secondaryTextColor
            basePeriod.font = periodFont

            return basePrice + basePeriod
        }

        var offerPrice = AttributedString(offer.price)
        offerPrice.foregroundColor = mainTextColor
        offerPrice.font = priceFont

        var offerPeriod = AttributedString(" /\(subscriptionPeriod)  ")
        offerPeriod.foregroundColor = secondaryTextColor
        offerPeriod.font = periodFont

        var basePrice = AttributedString("\(offer.rawPrice)/ \(subscriptionPeriod)")
        basePrice.foregroundColor = secondaryTextColor
        basePrice.font = periodFont
        basePrice.strikethroughStyle = .single

        return offerPrice + offerPeriod + basePrice
    }

    private func offerDescription(for subscriptionInfo: ProductInfo) -> String? {
        guard let offer = subscriptionInfo.offer else {
            return nil
        }
        return offer.description
    }
}

/// Switches between an HStack and VStack on iOS 16, and defaults to a VStack below
private struct OfferStack<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    content()
                }

                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
        }
    }
}

#Preview {
    SubscriptionPriceAndOfferView(product: PlusPricingInfoModel.PlusProductPricingInfo(identifier: .monthly, price: "9.99", rawPrice: "9.99", offer: nil), mainTextColor: .black, secondaryTextColor: .gray)
}
