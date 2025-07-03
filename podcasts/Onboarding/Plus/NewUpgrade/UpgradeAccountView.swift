import SwiftUI

struct UpgradeAccountView: View {

    @Environment(\.dismiss) var dismiss

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
            UpgradeProductsView(model: model)
        }
        .padding(24)
    }

    var header: some View {
        HStack() {
            SubscriptionBadge(tier: .plus)
            Spacer()
            Button() {
                dismiss()
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

#Preview {
    UpgradeAccountView(model: UpgradeAccountViewModel())
}
