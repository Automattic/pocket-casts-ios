import SwiftUI

struct CancelSubscriptionPlanRow: View {
    @EnvironmentObject var theme: Theme

    let product: PlusPricingInfoModel.PlusProductPricingInfo
    var selected: Bool
    let onTap: (PlusPricingInfoModel.PlusProductPricingInfo) -> Void

    @State private var badgeHeight: CGFloat = 0

    var badge: some View {
        VStack {
            HStack {
                Spacer()
                Text(L10n.cancelSubscriptionAvailablePlansBestValueBadge)
                    .font(size: 14.0, style: .body, weight: .medium)
                    .foregroundStyle(theme.primaryInteractive02)
                    .frame(minHeight: 24.0)
                    .padding(.horizontal, 16.0)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 12.0,
                            style: .continuous
                        )
                        .fill(theme.primaryField03Active)
                    )
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    badgeHeight = proxy.size.height
                                }
                                .onChange(of: proxy.size.height) {
                                    badgeHeight = $0
                                }
                        }
                    )
            }
            .padding(.trailing, 12.0)
            .padding(.top, -badgeHeight * 0.5)
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
                .frame(minHeight: 64)
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
                        .foregroundStyle(theme.primaryText01)
                    Text(product.frequencyPrice)
                        .font(size: 15.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText02)
                }
                .padding(.vertical, 10.0)
                Spacer()
                if let monthlyPrice = product.formattedMonthlyPrice {
                    Text(monthlyPrice)
                        .font(size: 15.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText02)
                }
            }
            .padding(.horizontal, 16.0)
            if product.isBestValue {
                badge
                    .frame(minHeight: 64)
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

    fileprivate var formattedMonthlyPrice: String? {
        switch identifier {
        case .yearly, .yearlyReferral, .patronYearly:
            if let monthlyPrice = monthlyPrice, !monthlyPrice.isEmpty {
                return L10n.iapProductMonthlyPricingFormat(monthlyPrice)
            }
            return nil
        case .monthly, .patronMonthly:
            return nil
        }
    }

    var isBestValue: Bool {
        switch identifier {
        case .yearly, .patronYearly:
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
                    monthlyPrice: "$3.33",
                    offer: nil,
                    basePrice: 39.99),
                selected: true
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
            CancelSubscriptionPlanRow(
                product: .init(
                    identifier: .monthly,
                    price: "",
                    rawPrice: "$3.99",
                    weeklyPrice: "",
                    monthlyPrice: nil,
                    offer: nil,
                    basePrice: 3.99),
                selected: false
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
            CancelSubscriptionPlanRow(
                product: .init(
                    identifier: .yearlyReferral,
                    price: "",
                    rawPrice: "$39.99",
                    weeklyPrice: "$0.70",
                    monthlyPrice: "",
                    offer: nil,
                    basePrice: 39.99),
                selected: false
            ) { _ in }
                .environmentObject(Theme.sharedTheme)
        }
        .background(.gray)
        .previewLayout(.fixed(width: 393, height: 300))
        .padding(.vertical, 16.0)
    }
}
