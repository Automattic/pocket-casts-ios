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
                                expand = true
                                withAnimation {
                                    proxy.scrollTo("extra", anchor: .bottom)
                                }
                            } label: {
                                Text(L10n.subscriptionPlanFreeTrialInfoLink)
                                    .font(.subheadline)
                                    .foregroundColor(theme.primaryInteractive01)
                            }
                        }
                        Spacer()
                        if expand, model.isFreeTrialAvailable {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("Placeholder View - Variant B")
                                        .foregroundStyle(theme.primaryText01)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 200)
                            .id("extra")
                        } else {
                            EmptyView()
                                .id("extra")
                        }
                    }
                }
                .scrollIndicators(.never)
            }
            UpgradeProductsView(model: model)
        }
        .padding(24)
        .background(theme.primaryUi01)
    }

    var header: some View {
        HStack() {
            SubscriptionBadge(tier: model.upgradeTier.tier)
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
    UpgradeAccountView(model: UpgradeAccountViewModel()).setupDefaultEnvironment()
}
