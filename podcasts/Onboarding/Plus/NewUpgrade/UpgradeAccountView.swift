import SwiftUI

class UpgradeAccountViewModel: PlusPricingInfoModel {

    @Published var upgradeTier: UpgradeTier = .plus
    @Published var selectedProduct: IAPProductID = .yearly
    @Published var products: [PlusProductPricingInfo] = []

    init() {
        super.init()
        loadPrices() {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.products = self.pricingInfo.products.filter {
                    self.upgradeTier.plan.products.contains($0.identifier)
                }
            }
        }
    }

    var features: [UpgradeTier.TierFeature] {
        return upgradeTier.monthlyFeatures
    }

    var isFreeTrialAvailable: Bool {
        guard let product = pricingInfo.products.first(where: {$0.identifier == selectedProduct}) else {
            return false
        }
        guard let offer = product.offer else {
            return false
        }

        return offer.type == .freeTrial
    }
}

struct UpgradeAccountView: View {

    @ObservedObject var model: UpgradeAccountViewModel
    @State var expand: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            header
            title
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack { Spacer() }
                        UpgradeFeaturesView(features: model.upgradeTier.monthlyFeatures)
                        if model.isFreeTrialAvailable {
                            Button {
                                expand.toggle()
                                withAnimation {
                                    proxy.scrollTo("extra", anchor: .bottom)
                                }
                            } label: {
                                Text("How does the free trial work?")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.01, green: 0.66, blue: 0.96))
                            }
                        }
                        Spacer()
                        if expand {
                            UpgradeFeaturesView(features: model.features)
                                .id("extra")
                        } else {
                            EmptyView()
                                .id("extra")
                        }
                    }
                }
            }
            UpgradeScreenProductsInfoView(model: model)
        }
        .padding(24)
    }

    var header: some View {
        HStack() {
            SubscriptionBadge(tier: .plus)
            Spacer()
            Button() {

            } label: {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
    }

    var title: some View {
        HStack {
            Text(L10n.upgradeAccountTitle)
                .font(.largeTitle).fontWeight(.bold)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }

    var options: some View {
        VStack {

        }
    }
}

struct UpgradeScreenProductsInfoView: View {
    let model: UpgradeAccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.products, id: \.self.id) { product in
                HStack(alignment: .center) {
                    Image(systemName: true ? "checkmark" : "circle")
                    VStack(alignment: .leading) {
                        Text(product.price)
                            .font(.subheadline).fontWeight(.bold)
                        Text(product.price)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(product.weeklyPrice)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.gray)
                }
                .padding(16)
                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                .cornerRadius(12)
                .overlay {
                    if true {
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 1)
                                .stroke(Color(red: 0.01, green: 0.66, blue: 0.96), lineWidth: 2)
                            badge.offset(x: 0, y: -10)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            Spacer().frame(height: 16)
            actionButton
        }
    }

    var badge: some View {
        HStack(alignment: .center, spacing: 0) {
            Text ("Offer")
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .background(Color(red: 0.01, green: 0.66, blue: 0.96))
        .cornerRadius(800)
        .overlay(
            RoundedRectangle(cornerRadius: 800)
                .inset(by: 0.5)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    var actionButton: some View {
        Button("Purchase") {

        }
//        SubscriptionPurchaseButton(viewModel: viewModel) {
//
//        }
//        .frame(maxWidth: 440)
    }
}

#Preview {
    UpgradeAccountView(model: UpgradeAccountViewModel())
}
