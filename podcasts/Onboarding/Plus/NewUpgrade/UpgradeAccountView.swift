import SwiftUI

struct UpgradeAccountView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: UpgradeAccountViewModel

    @State private var expand: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer().frame(height: 24)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        title
                        UpgradeFeaturesView(features: model.features)
                        if model.isFreeTrialAvailable {
                            Button {
                                expand = true
                                withAnimation {
                                    proxy.scrollTo("next_page", anchor: .top)
                                }
                            } label: {
                                Text(L10n.subscriptionPlanFreeTrialInfoLink)
                                    .font(.subheadline)
                                    .foregroundColor(theme.primaryInteractive01)
                            }
                        }
                        if expand, model.isFreeTrialAvailable {
                            UpgradeTimelineView(events: TimelineEvent.sampleEvents)
                            .id("next_page")
                            .padding(.bottom, 300)
                        } else {
                            EmptyView()
                                .id("next_page")
                        }
                    }
                }
                .scrollIndicators(.never)
            }
            UpgradeProductsView(model: model)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(theme.primaryUi01)
    }

    var header: some View {
        HStack() {
            SubscriptionBadge(tier: model.upgradeTier.tier, displayMode: .plain)
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
            Text(model.upgradeTier.header)
                .font(size: 32, style: .largeTitle, weight: .bold)
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
