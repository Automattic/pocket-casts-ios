import SwiftUI

struct UpgradeAccountView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: UpgradeAccountViewModel

    @State private var expand: Bool = false

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
                                    .foregroundColor(theme.primaryInteractive01)
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
        .background(theme.primaryUi01)
    }

    var header: some View {
        HStack() {
            SubscriptionBadge(tier: .plus)
            Spacer()
            Button() {
                dismiss()
            } label: {
                HStack {
                    Image("close")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(theme.primaryIcon01)
                }
                .padding(4)
                .background(theme.primaryUi05)
                .cornerRadius(50)
            }
        }
    }

    var title: some View {
        HStack {
            Text(L10n.upgradeAccountTitle)
                .font(.largeTitle).fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.primaryText01)
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
