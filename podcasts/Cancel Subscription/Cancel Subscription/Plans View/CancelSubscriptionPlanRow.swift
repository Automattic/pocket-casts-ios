import SwiftUI

struct CancelSubscriptionPlanRow: View {
    @EnvironmentObject var theme: Theme

    let product: PlusPricingInfoModel.PlusProductPricingInfo
    var selected: Bool
    let onTap: (PlusPricingInfoModel.PlusProductPricingInfo) -> Void

    var badge: some View {
        VStack {
            HStack {
                Spacer()
                Text(L10n.cancelSubscriptionAvailablePlansBestValueBadge)
                    .font(size: 14.0, style: .body, weight: .regular)
                    .foregroundStyle(theme.primaryInteractive02)
                    .frame(height: 24.0)
                    .padding(.horizontal, 16.0)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 12.0,
                            style: .continuous
                        )
                        .fill(theme.primaryField03Active)
                    )
            }
            .padding(.trailing, 12.0)
            .padding(.top, -12.0)
            Spacer()
        }
    }

    @ViewBuilder
    var tick: some View {
        if selected {
            ZStack {
                Circle()
                    .fill(theme.primaryField03Active)
                Image("small-tick")
                    .resizable()
                    .foregroundColor(theme.primaryInteractive02)
            }
        } else {
            Circle()
                .fill(theme.primaryUi01Active)
                .overlay(
                        Circle()
                            .stroke(theme.primaryInteractive03, lineWidth: 2)
                    )
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.clear)
                .background(theme.primaryUi01Active)
                .cornerRadius(8.0)
                .frame(height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.0)
                        .stroke(theme.primaryField03Active,
                                lineWidth: selected ? 2 : 0)
                )
            HStack(spacing: 16.0) {
                tick
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 0) {
                    Text(product.planTitle)
                        .font(size: 18.0, style: .body, weight: .bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(theme.primaryText01)
                    Text(product.frequencyPrice)
                        .font(size: 15.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText02)
                }
                Spacer()
                if let weeklyPrice = product.formattedWeeklyPrice {
                    Text(weeklyPrice)
                        .font(size: 15.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText02)
                }
            }
            .padding(.horizontal, 16.0)
            if product.isBestValue {
                badge
                    .frame(height: 64)
            }
        }
        .padding(.horizontal, 20.0)
        .onTapGesture {
            onTap(product)
        }
    }
}

extension PlusPricingInfoModel.PlusProductPricingInfo {
    fileprivate var planTitle: String {
        switch identifier {
        case .yearly:
            return "Plus \(L10n.yearly.capitalized)"
        case .yearlyReferral:
            return "Plus \(L10n.yearly.capitalized) - Referral"
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

    fileprivate var formattedWeeklyPrice: String? {
        switch identifier {
        case .yearly, .yearlyReferral, .patronYearly:
            return weeklyPrice.isEmpty ? nil : L10n.iapProductWeeklyPricingFormat(weeklyPrice)
        case .monthly, .patronMonthly:
            return nil
        }
    }

    fileprivate var isBestValue: Bool {
        switch identifier {
        case .yearly:
            return true
        default:
            return false
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
                    weeklyPrice: "$0.70",
                    offer: nil),
                selected: true
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
            CancelSubscriptionPlanRow(
                product: .init(
                    identifier: .monthly,
                    price: "",
                    rawPrice: "$3.99",
                    weeklyPrice: "",
                    offer: nil),
                selected: false
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
            CancelSubscriptionPlanRow(
                product: .init(
                    identifier: .yearlyReferral,
                    price: "",
                    rawPrice: "$39.99",
                    weeklyPrice: "$0.70",
                    offer: nil),
                selected: false
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
        }
        .background(.gray)
        .previewLayout(.fixed(width: 393, height: 300))
        .padding(.vertical, 16.0)
    }
}
