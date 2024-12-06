import SwiftUI

struct CancelSubscriptionPlanRow: View {
    @EnvironmentObject var theme: Theme

    let product: PlusPricingInfoModel.PlusProductPricingInfo
    var selected: Bool
    let onTap: (PlusPricingInfoModel.PlusProductPricingInfo) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.clear)
                .background(theme.primaryUi01)
                .cornerRadius(8.0)
                .frame(height: 64)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text(product.planTitle)
                        .font(size: 18.0, style: .body, weight: .bold)
                        .foregroundStyle(theme.primaryText01)
                    Spacer()
                    if selected {
                        ZStack {
                            Circle()
                                .fill(theme.primaryField03Active)
                                .frame(width: 24, height: 24)
                            Image("small-tick")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(theme.primaryInteractive02)
                        }
                    }
                }
                HStack(spacing: 0) {
                    Text(product.frequencyPrice)
                        .font(size: 15.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText01)
                    Spacer()
                }
            }
            .padding(.leading, 20.0)
            .padding(.trailing, 10.0)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8.0)
                .stroke(theme.primaryField03Active,
                        lineWidth: selected ? 2 : 0)
        )
        .padding(.horizontal, 20.0)
        .onTapGesture {
            onTap(product)
        }
    }
}

extension PlusPricingInfoModel.PlusProductPricingInfo {
    fileprivate var planTitle: String {
        switch identifier {
        case .yearly, .yearlyReferral:
            return "Plus \(L10n.yearly.capitalized)"
        case .monthly:
            return "Plus \(L10n.monthly.capitalized)"
        case .patronMonthly:
            return "Patron \(L10n.monthly.capitalized)"
        case .patronYearly:
            return "Patron \(L10n.yearly.capitalized)"
        }
    }

    fileprivate var frequencyPrice: String {
        switch identifier {
        case .yearly, .yearlyReferral, .patronYearly:
            return L10n.plusYearlyFrequencyPricingFormat(rawPrice)
        case .monthly, .patronMonthly:
            return L10n.plusMonthlyFrequencyPricingFormat(rawPrice)
        }
    }
}

struct CancelSubscriptionPlanRow_Preview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16.0) {
            CancelSubscriptionPlanRow(
                product: .init(
                    identifier: .yearly,
                    price: "",
                    rawPrice: "$39.99",
                    offer: nil),
                selected: true
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
            CancelSubscriptionPlanRow(
                product: .init(
                    identifier: .monthly,
                    price: "",
                    rawPrice: "$3.99",
                    offer: nil),
                selected: false
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
        }
        .background(.gray)
        .previewLayout(.fixed(width: 393, height: 250))
    }
}
