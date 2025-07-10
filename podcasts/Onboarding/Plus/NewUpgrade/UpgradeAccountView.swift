import SwiftUI

struct UpgradeAccountView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: UpgradeAccountViewModel

    @State private var expand: Bool = false

    @State private var flash: Bool = false

    enum ScrollPosition: String {
        case firstPage
        case secondPage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer().frame(height: 24)
            GeometryReader() { sizeProxy in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            title
                                .id(ScrollPosition.firstPage)
                            UpgradeFeaturesView(features: model.features)
                            if model.isFreeTrialAvailable {
                                Button {
                                    expand = true
                                    withAnimation {
                                        proxy.scrollTo(ScrollPosition.secondPage, anchor: .top)
                                    }
                                } label: {
                                    Text(L10n.subscriptionPlanFreeTrialInfoLink)
                                        .font(.subheadline)
                                        .foregroundColor(theme.primaryInteractive01)
                                }
                            }
                            if expand, model.isFreeTrialAvailable {
                                UpgradeTimelineView(events: model.timelineEvents)
                                    .id(ScrollPosition.secondPage)
                                    .frame(minHeight: sizeProxy.size.height)
                            } else {
                                EmptyView()
                                    .id(ScrollPosition.secondPage)
                            }
                        }
                    }
                    .scrollIndicators(.visible)
                    .withScrollFlashIndicator(trigger: flash)
                    .overlay(alignment: .bottom, content: {
                        gradientSpacer
                    })
                    .onChange(of: model.selectedProduct) { _ in
                        if !model.isFreeTrialAvailable {
                            withAnimation {
                                expand = false
                                proxy.scrollTo(ScrollPosition.firstPage)
                            }
                        }
                    }
                }
            }
            UpgradeProductsView(model: model)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(theme.primaryUi01)
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5.seconds) {
                flash.toggle()
            }
        }
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

    var gradientSpacer: some View {
        HStack() {
            Spacer()
        }
        .frame(height: 40)
        .background(LinearGradient(colors: [
            theme.primaryUi01.opacity(0),
            theme.primaryUi01.opacity(1)
        ], startPoint: UnitPoint.top, endPoint: UnitPoint.bottom))
        .allowsHitTesting(false)
    }
}

// MARK: - Special modifier to support versions previous than iOS 17
struct WithScrollFlashIndicatorModifier: ViewModifier {

    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollIndicatorsFlash(trigger: trigger)
        } else {
            content
        }
    }
}

extension View {
    func withScrollFlashIndicator(trigger: Bool) -> some View {
        self.modifier(WithScrollFlashIndicatorModifier(trigger: trigger))
    }
}

#Preview {
    UpgradeAccountView(model: UpgradeAccountViewModel()).setupDefaultEnvironment()
}
