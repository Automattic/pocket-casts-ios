import SwiftUI
import PocketCastsServer

struct PlusPurchaseModal: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var coordinator: PlusPurchaseModel

    @State var selectedOption: IAPProductID
    @State var selectedOffer: PlusPricingInfoModel.ProductOfferInfo?

    var pricingInfo: PlusPurchaseModel.PlusPricingInfo {
        coordinator.pricingInfo
    }

    /// Whether or not all products have free trials, in this case we'll show the free trial label
    /// above the products and not inline
    let showGlobalTrial: Bool

    private var products: [PlusPricingInfoModel.PlusProductPricingInfo]

    init(coordinator: PlusPurchaseModel, selectedPrice: PlanFrequency = .yearly) {
        self.coordinator = coordinator

        self.products = coordinator.pricingInfo.products.filter { coordinator.plan.products.contains($0.identifier) }
        self.showGlobalTrial = products.allSatisfy { $0.offer != nil }

        let firstProduct = products.first
        _selectedOption = State(initialValue: selectedPrice == .yearly ? coordinator.plan.yearly : coordinator.plan.monthly)
        _selectedOffer = State(initialValue: firstProduct?.offer)
    }

    private func price(for subscriptionInfo: PlusPricingInfoModel.PlusProductPricingInfo) -> AttributedString {
        let subscriptionPeriod = subscriptionInfo.identifier.productInfo.frequency.description
        let mainTextColor = Color.white
        let secondaryTextColor = Color.gray
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

            var basePeriod = AttributedString("/ \(subscriptionPeriod)")
            basePeriod.foregroundColor = secondaryTextColor
            basePeriod.font = .footnote

            return basePrice + basePeriod
        }

        var offerPrice = AttributedString(offer.price)
        offerPrice.foregroundColor = mainTextColor
        offerPrice.font = .headline

        var offerPeriod = AttributedString(" /\(subscriptionPeriod)  ")
        offerPeriod.foregroundColor = secondaryTextColor
        offerPeriod.font = .footnote

        var basePrice = AttributedString("\(offer.rawPrice) /\(subscriptionPeriod)")
        basePrice.foregroundColor = secondaryTextColor
        basePrice.font = .footnote
        basePrice.strikethroughStyle = .single

        return offerPrice + offerPeriod + basePrice
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Label(coordinator.plan == .plus ? L10n.plusPurchasePromoTitle : L10n.patronPurchasePromoTitle, for: .title)
                .foregroundColor(Color.textColor)
                .padding(.top, 32)
                .padding(.bottom, pricingInfo.hasOffer ? 15 : 0)

            VStack(spacing: 16) {
                ForEach(products) { product in
                    // Hide any unselected items if we're in the failed state, this saves space for the error message
                    if coordinator.state != .failed || selectedOption == product.identifier {
                        ZStack(alignment: .center) {
                            Button() {
                                selectedOption = product.identifier
                                selectedOffer = product.offer
                            } label: {
                                Text(price(for: product))
                            }
                            .disabled(coordinator.state == .failed)
                            .buttonStyle(PlusGradientStrokeButton(isSelectable: true, plan: coordinator.plan, isSelected: selectedOption == product.identifier))
                            .overlay(
                                ZStack(alignment: .center) {
                                    if let offerDescription = product.offer?.description {
                                        GeometryReader { proxy in
                                            OfferLabel(offerDescription, plan: coordinator.plan, isSelected: selectedOption ==   product.identifier)
                                                .position(x: proxy.size.width * 0.5, y: proxy.frame(in: .local).minY)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }

                Label(pricingTermsLabel, for: .freeTrialTerms)
                    .foregroundColor(Color.textColor)
                    .lineSpacing(1.2)

                // Show the error message if we're in the failed state
                if coordinator.state == .failed {
                    PlusDivider()

                    Label(L10n.plusPurchaseFailed, for: .error).foregroundColor(.error)
                }

                PlusDivider()

                let isLoading = (coordinator.state == .purchasing)
                Button(subscribeButton) {
                    guard !isLoading else { return }
                    coordinator.purchase(product: selectedOption)
                }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: isLoading, plan: coordinator.plan)).disabled(isLoading)

                TermsView()
            }.padding(.top, 23)
        }
        .padding([.leading, .trailing])
        .background(Color.backgroundColor.ignoresSafeArea())
    }

    private var pricingTermsLabel: String {
        guard let selectedOffer else {
            return selectedOption.renewalPrompt
        }

        return selectedOffer.terms
    }

    private var subscribeButton: String {
        if coordinator.state == .failed {
            return L10n.tryAgain
        }

        return coordinator.plan == .plus ? L10n.plusSubscribeTo : L10n.patronSubscribeTo
    }

    enum Config {
        static let backgroundColorHex = "#282829"
    }

}

// MARK: - Config
private extension Color {
    static let backgroundColor = Color(hex: PlusPurchaseModal.Config.backgroundColorHex)
    static let textColor = Color(hex: "#FFFFFF")
    static let error = AppTheme.color(for: .support05)
}

// MARK: - Views
private struct PlusDivider: View {
    var body: some View {
        Divider().background(Color(hex: "#E4E4E4")).opacity(0.24)
    }
}

private struct TermsView: View {
    var body: some View {
        let purchaseTerms = L10n.purchaseTerms("$", "$", "$", "$").components(separatedBy: "$")

        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        Group {
            Text(purchaseTerms[safe: 0] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 1] ?? "")](\(privacyPolicy))")).underline() +
            Text(purchaseTerms[safe: 2] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 3] ?? "")](\(termsOfUse))")).underline()
        }
        .foregroundColor(.textColor)
        .font(style: .footnote)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Label: View {
    enum LabelStyle {
        case title
        case freeTrialTerms
        case error
    }

    let text: String
    let labelStyle: LabelStyle

    init(_ text: String, for style: LabelStyle) {
        self.text = text
        self.labelStyle = style
    }

    var body: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle))
            .multilineTextAlignment(.center)
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: LabelStyle

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 22, style: .title2, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .freeTrialTerms:
                return content.font(size: 13, style: .caption, maxSizeCategory: .extraExtraLarge)
            case .error:
                return content.font(style: .subheadline, maxSizeCategory: .extraExtraExtraLarge)
            }
        }
    }
}

// MARK: - Preview
struct PlusPurchaseOptions_Previews: PreviewProvider {
    static var previews: some View {
        PlusPurchaseModal(coordinator: PlusPurchaseModel())
            .setupDefaultEnvironment()
    }
}
