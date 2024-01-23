//
//  SubscriptionPriceAndOfferView.swift
//  podcasts
//
//  Created by Sérgio Estêvão on 23/01/2024.
//  Copyright © 2024 Shifty Jelly. All rights reserved.
//

import SwiftUI

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

    private func price(for subscriptionInfo: ProductInfo) -> AttributedString {
        let subscriptionPeriod = subscriptionInfo.identifier.productInfo.frequency.description

        guard let offer = subscriptionInfo.offer else {
            var basePrice =  AttributedString(subscriptionInfo.rawPrice)
            basePrice.font = .headline
            basePrice.foregroundColor = mainTextColor

            var basePeriod = AttributedString("/ \(subscriptionPeriod)")
            basePeriod.foregroundColor = secondaryTextColor
            basePeriod.font = .footnote

            return basePrice + basePeriod
        }


        if offer.type == .freeTrial {
            var basePrice =  AttributedString(subscriptionInfo.rawPrice)
            basePrice.font = .headline
            basePrice.foregroundColor = mainTextColor

            var basePeriod = AttributedString("/\(subscriptionPeriod)")
            basePeriod.foregroundColor = secondaryTextColor
            basePeriod.font = .footnote

            return basePrice + basePeriod
        }

        var offerPrice = AttributedString(offer.price)
        offerPrice.foregroundColor = mainTextColor
        offerPrice.font = .headline

        var offerPeriod = AttributedString(" /\(subscriptionPeriod)")
        offerPeriod.foregroundColor = secondaryTextColor
        offerPeriod.font = .footnote

        var basePrice = AttributedString(" \(offer.rawPrice)/\(subscriptionPeriod)")
        basePrice.foregroundColor = secondaryTextColor
        basePrice.font = .footnote
        basePrice.strikethroughStyle = .single

        return offerPrice + offerPeriod + basePrice
    }

    private func offerDescription(for subscriptionInfo: ProductInfo) -> String? {
        guard let offer = subscriptionInfo.offer else {
            return nil
        }
        return offer.description
    }

    var body: some View {
        Text(price(for: product))
            .padding(.bottom, 10)
        if let offerDescription = offerDescription(for: product) {
            Text(offerDescription)
                .foregroundColor(product.identifier.plan == .plus ? Color.black : Color.white)
                .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                .background(product.identifier.plan == .plus ? Color.plusBackgroundColor2 : Color.patronBackgroundColor)
                .textCase(.uppercase)
                .font(style: .caption2, weight: .semibold)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.bottom, 12)
        }
    }
}

#Preview {
    SubscriptionPriceAndOfferView(product: PlusPricingInfoModel.PlusProductPricingInfo(identifier: .monthly, price: "9.99", rawPrice: "9.99", offer: nil), mainTextColor: .black, secondaryTextColor: .gray)
}
