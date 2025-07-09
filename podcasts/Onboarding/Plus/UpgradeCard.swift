import Foundation
import SwiftUI
import PocketCastsServer
import PocketCastsUtils

struct UpgradeCard: View {
    @EnvironmentObject var viewModel: PlusLandingViewModel

    @EnvironmentObject var theme: Theme

    @Environment(\.openURL) private var openURL

    @Environment(\.sizeCategory) private var sizeCategory

    let tier: UpgradeTier

    let currentPrice: Binding<PlanFrequency>

    let subscriptionInfo: PlusPricingInfoModel.PlusProductPricingInfo?

    let showPurchaseButton: Bool

    private var subscriptionPriceSecondaryTextColor: Color {
        if theme.activeTheme == .light {
            return Color(hex: "#6F7580")
        }
        return theme.primaryText02
    }

    private var termsAndConditionsTextColor: Color {
        if theme.activeTheme == .light {
            return Color(hex: "#6F7580")
        }
        return theme.primaryText01
    }

    private var termsAndConditionsOpacity: Double {
        if theme.activeTheme == .light {
            return 1.0
        }
        return 0.64
    }

    private var featureSpacing: CGFloat {
        max(16.0, 16.0 * ScaleFactorModifier.scaleFactor(for: sizeCategory))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                if let subscriptionInfo {
                    SubscriptionPriceAndOfferView(product: subscriptionInfo, mainTextColor: theme.primaryText01, secondaryTextColor: subscriptionPriceSecondaryTextColor)
                } else {
                    SubscriptionBadge(tier: tier.tier)
                        .padding(.bottom, 12)
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(currentPrice.wrappedValue == .monthly ? tier.monthlyFeatures : tier.yearlyFeatures, id: \.self) { feature in
                        HStack(spacing: featureSpacing) {
                            Image(feature.iconName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleFactor(for: sizeCategory)
                                .foregroundColor(theme.primaryText01)
                                .frame(width: 16, height: 16)
                            UnderlineLinkTextView(feature.title)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(theme.primaryText01)
                                .tint(theme.primaryText01)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    termsAndConditions
                        .font(style: .footnote).fixedSize(horizontal: false, vertical: true)
                        .tint(termsAndConditionsTextColor)
                        .opacity(termsAndConditionsOpacity)
                    if showPurchaseButton {
                        purchaseButton
                    }
                }
                .padding(.bottom, 0)
            }
            .padding(24)

        }
        .background(theme.primaryUi01)
        .cornerRadius(24)
        .shadow(color: theme.primaryText01.opacity(0.01), radius: 10, x: 0, y: 24)
        .shadow(color: theme.primaryText01.opacity(0.05), radius: 8, x: 0, y: 14)
        .shadow(color: theme.primaryText01.opacity(0.09), radius: 6, x: 0, y: 6)
        .shadow(color: theme.primaryText01.opacity(0.1), radius: 3, x: 0, y: 2)
        .shadow(color: theme.primaryText01.opacity(0.1), radius: 0, x: 0, y: 0)
    }

    @ViewBuilder
    var termsAndConditions: some View {
        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        Text(L10n.termsAndConditions)
        .foregroundColor(termsAndConditionsTextColor)
        .environment(\.openURL, OpenURLAction { url in
            switch url.absoluteString {
            case privacyPolicy:
                viewModel.privacyPolicyTapped()
            case termsOfUse:
                viewModel.termsOfUseTapped()
            default:
                break
            }
            return .systemAction
        })
    }

    @ViewBuilder
    var purchaseButton: some View {
        let hasError = Binding<Bool>(
            get: { self.viewModel.state == .failed },
            set: { _ in }
        )
        let isLoading = (viewModel.state == .purchasing) || (viewModel.priceAvailability == .loading)
        Button(action: {
            viewModel.unlockTapped(.init(plan: tier.plan, frequency: currentPrice.wrappedValue))
        }, label: {
            VStack {
                Text(purchaseTitle)
            }
            .transition(.opacity)
            .id("plus_price" + tier.title)
        })
        .buttonStyle(PlusOpaqueButtonStyle(isLoading: isLoading, plan: tier.plan))
        .alert(isPresented: hasError) {
            Alert(
                title: Text(L10n.plusPurchaseFailed),
                dismissButton: .default(Text(L10n.ok)) {
                    viewModel.reset()
                }
            )
        }
    }

    private var purchaseTitle: String {
        guard let subscriptionInfo = viewModel.pricingInfo(for: tier, frequency: currentPrice.wrappedValue) else {
            return tier.buttonLabel
        }

        if subscriptionInfo.offer?.type == .freeTrial {
            return L10n.freeTrialStartButton
        }

        return tier.buttonLabel
    }
}
