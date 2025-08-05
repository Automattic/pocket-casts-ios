import SwiftUI
import PocketCastsServer

struct UpgradeProductsView: View {

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: UpgradeAccountViewModel

    @ScaledMetric(relativeTo: .body) private var badgeOffset: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.products, id: \.self.id) { product in
                row(for: product)
            }
            VStack(spacing: 0) {
                Spacer().frame(height: 6)
                actionButton
                Spacer().frame(height: 12)
                HStack {
                    Spacer()
                    termsAndConditions
                    Spacer()
                }
                Spacer().frame(height: 4)
            }
        }
    }

    func row(for product: PlusPricingInfoModel.PlusProductPricingInfo) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(product.identifier == model.selectedProduct ? "rounded-selected" : "rounded-deselected")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(theme.primaryIcon01)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 8) {
                Text(product.periodDescription)
                    .font(size: 15, style: .subheadline, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .fixedSize(horizontal: true, vertical: false)
                Text(product.periodPrice)
                    .font(size: 15, style: .subheadline, weight: .medium)
                    .foregroundStyle(theme.primaryText02)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .multilineTextAlignment(.leading)
            Spacer()
            Text(product.weeklyPeriodPrice)
                .font(size: 15, style: .subheadline, weight: .medium)
                .foregroundStyle(theme.primaryText02)
        }
        .padding(16)
        .frame(minHeight: 75)
        .background(theme.primaryUi03)
        .cornerRadius(12)
        .overlay {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 1)
                    .stroke(product.identifier == model.selectedProduct ? theme.primaryInteractive01 : .clear, lineWidth: 2)
                if product.isBestValue, model.savingsOnBestValue != nil {
                    badge
                        .offset(x: 0, y: -badgeOffset)
                }
            }
        }
        .onTapGesture {
            withAnimation {
                model.selectProduct(product.identifier)
            }
        }
    }

    var badge: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(model.savingsOnBestValue ?? "")
                .foregroundStyle(theme.primaryUi01)
                .font(size: 14, style: .footnote, weight: .medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .background(theme.primaryInteractive01)
        .cornerRadius(800)
        .overlay(
            RoundedRectangle(cornerRadius: 800)
                .inset(by: 0.5)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    var actionButton: some View {
        SubscriptionPurchaseButton(viewModel: model, tier: model.upgradeTier, frequency: model.selectedFrequency, showPurchaseErrors: true) {
            model.purchaseTapped()
        }
    }

    @ViewBuilder
    var termsAndConditions: some View {
        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        Text(L10n.termsAndConditions)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        .foregroundColor(theme.primaryText02)
        .tint(theme.primaryText02)
        .font(size: 11, style: .caption2, weight: .semibold)
        .environment(\.openURL, OpenURLAction { url in
            switch url.absoluteString {
                case privacyPolicy:
                    model.privacyPolicyTapped()
                case termsOfUse:
                    model.termsOfUseTapped()
                default:
                    break
            }
            return .systemAction
        })
    }
}

extension L10n {
    static var termsAndConditions: AttributedString {
        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        let privacyPolicyText = L10n.accountPrivacyPolicy.nonBreakingSpaces()
        let termsOfUseText = L10n.termsOfUse.nonBreakingSpaces()

        // Create markdown formatted text with proper localization
        let termsMarkdown = L10n.purchaseTerms(
            "[\(privacyPolicyText)](\(privacyPolicy))",
            "[\(termsOfUseText)](\(termsOfUse))"
        )

        var attributedString = try! AttributedString(markdown: termsMarkdown)

        // Add underline to all links
        attributedString.runs.forEach { run in
            if run.link != nil {
                attributedString[run.range].underlineStyle = .single
            }
        }

        return attributedString
    }
}

#Preview {
    UpgradeProductsView(model: UpgradeAccountViewModel(flowSource: PlusLandingViewModel.Source.upsell)).setupDefaultEnvironment()
}

extension PlusPricingInfoModel.PlusProductPricingInfo {

    var periodPrice: String {
        self.rawPrice + (self.identifier.isYearlyProduct ? "/\((L10n.year))" : "/\(L10n.month)")
    }

    var periodDescription: String {
        self.identifier.isYearlyProduct ? L10n.subscriptionPlanYear : L10n.subscriptionPlanMonth
    }

    var weeklyPeriodPrice: String {
        self.weeklyPrice + "/\(L10n.week)"
    }
}
