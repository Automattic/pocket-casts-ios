import SwiftUI
import PocketCastsServer

struct UpgradeProductsView: View {

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: UpgradeAccountViewModel

    @State private var selected: IAPProductID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.products, id: \.self.id) { product in
                HStack(alignment: .center) {
                    Image(product.identifier == selected ? "rounded-selected" : "rounded-deselected")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(theme.primaryIcon01)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading) {
                        Text(product.price)
                            .font(size: 15, style: .subheadline, weight: .bold)
                            .foregroundStyle(theme.primaryText01)
                        Text(product.price)
                            .font(size: 15, style: .subheadline, weight: .medium)
                            .foregroundStyle(theme.primaryText02)
                    }
                    Spacer()
                    Text(product.weeklyPrice)
                        .font(size: 15, style: .subheadline, weight: .medium)
                        .foregroundStyle(theme.primaryText02)
                }
                .padding(16)
                .background(theme.primaryUi03)
                .cornerRadius(12)
                .overlay {
                    if product.identifier == selected {
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 1)
                                .stroke(Color(red: 0.01, green: 0.66, blue: 0.96), lineWidth: 2)
                            if let offer = product.offer {
                                badge
                                    .offset(x: 0, y: -10)
                            }
                        }
                    } else {
                        EmptyView()
                    }
                }
                .onTapGesture {
                    selected = product.identifier
                }
            }
            Spacer().frame(height: 16)
            actionButton
            HStack {
                Spacer()
                termsAndConditions
                Spacer()
            }
        }
    }

    var badge: some View {
        HStack(alignment: .center, spacing: 0) {
            Text ("Save 16%")
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
        SubscriptionPurchaseButton(viewModel: model) {

        }
        .frame(maxWidth: 600)
    }

    @ViewBuilder
    var termsAndConditions: some View {
        let purchaseTerms = L10n.purchaseTerms("$", "$", "$", "$").components(separatedBy: "$")

        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        Group {
            Text(purchaseTerms[safe: 0] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 1] ?? "")](\(privacyPolicy))")).underline() +
            Text(purchaseTerms[safe: 2] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 3] ?? "")](\(termsOfUse))")).underline()
        }
        .multilineTextAlignment(.center)
        .foregroundColor(theme.secondaryText02)
        .font(size: 11, style: .caption2, weight: .semibold)
        .environment(\.openURL, OpenURLAction { url in
            switch url.absoluteString {
                case privacyPolicy:
                    break
                    //viewModel.privacyPolicyTapped()
                case termsOfUse:
                    //viewModel.termsOfUseTapped()
                    break
                default:
                    break
            }
            return .systemAction
        })
    }
}
