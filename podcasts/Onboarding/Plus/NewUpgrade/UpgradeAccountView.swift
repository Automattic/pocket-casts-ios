import SwiftUI
import PocketCastsUtils

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
            scrollableContent
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
                model.dismissTapped(originalDismiss: dismiss)
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

    @ViewBuilder
    var pageOne: some View {
        VStack(spacing: 0) {
            if FeatureFlag.newOnboardingVariant.enabled, model.isFreeTrialAvailable {
                UpgradeTimelineView(events: model.timelineEvents)
            } else {
                UpgradeFeaturesView(features: model.features)
            }
        }
    }

    @ViewBuilder
    var pageTwo: some View {
        if FeatureFlag.newOnboardingVariant.enabled, model.isFreeTrialAvailable {
            UpgradeFeaturesView(features: model.features)
        } else {
            UpgradeTimelineView(events: model.timelineEvents)
        }
    }

    var scrollableContent: some View {
        GeometryReader() { sizeProxy in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        title.id(ScrollPosition.firstPage)
                        Spacer().frame(height: 24)
                        pageOne
                        if model.isFreeTrialAvailable {
                            Button {
                                expand = true
                                withAnimation {
                                    proxy.scrollTo(ScrollPosition.secondPage, anchor: .top)
                                }
                            } label: {
                                Text(FeatureFlag.newOnboardingVariant.enabled ? L10n.subscriptionPlanFeaturesInfoLink : L10n.subscriptionPlanFreeTrialInfoLink)
                                    .font(size: 15, style: .subheadline, weight: .medium)
                                    .foregroundColor(theme.primaryInteractive01)
                            }
                            .padding(.vertical, 24)
                        }
                        if expand, model.isFreeTrialAvailable {
                            VStack {
                                pageTwo
                                Spacer()
                            }
                            .id(ScrollPosition.secondPage)
                            .frame(minHeight: sizeProxy.size.height)
                        } else {
                            Spacer()
                                .id(ScrollPosition.secondPage)
                                .frame(height: 8)
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
    }

    var title: some View {
        HStack {
            Text(model.title)
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
    UpgradeAccountView(model: UpgradeAccountViewModel(flowSource: PlusLandingViewModel.Source.upsell)).setupDefaultEnvironment()
}
