import SwiftUI
import PocketCastsUtils

struct UpgradeAccountView: View {

    @Environment(\.dismiss) var dismiss

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @EnvironmentObject var theme: Theme

    @ObservedObject var model: UpgradeAccountViewModel

    @State private var expand: Bool = false

    @State private var flash: Bool = false

    enum ScrollPosition: String {
        case firstPage
        case secondPage
    }

    enum Constants {
        static let gradientHeight: CGFloat = 24
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                scrollableContent(proxy: proxy)
                    .overlay(alignment: .top) {
                        gradient(height: Constants.gradientHeight, up: true)
                    }
                    .overlay(alignment: .bottom) {
                        gradient(height: Constants.gradientHeight, up: false)
                    }
                if showsPinnedDetailsButton {
                    detailsButton(text: detailsButtonText, proxy: proxy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }
                UpgradeProductsView(model: model)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.top, 16)
        .background(theme.primaryUi01)
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5.seconds) {
                flash.toggle()
            }
        }
    }

    private var showsDetailsButton: Bool {
        model.style == .generic && model.isFreeTrialAvailable && FeatureFlag.newOnboardingUpgradeTrialTimeline.enabled
    }

    private var showsPinnedDetailsButton: Bool {
        showsDetailsButton && !dynamicTypeSize.isAccessibilitySize
    }

    private var detailsButtonText: String {
        model.shouldShowVariation ? L10n.subscriptionPlanFeaturesInfoLink : L10n.subscriptionPlanFreeTrialInfoLink
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

    var contextualAnimation: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                model.customAnimation
                Spacer()
            }
            Spacer()
        }
    }

    @ViewBuilder
    func pageOne(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            title.id(ScrollPosition.firstPage)
            switch model.style {
                case .generic:
                    VStack(alignment: .leading) {
                        Spacer().frame(height: 24)
                        if model.shouldShowVariation {
                            UpgradeTimelineView(events: model.timelineEvents)
                        } else {
                            UpgradeFeaturesView(features: model.features)
                        }
                        if showsDetailsButton, !showsPinnedDetailsButton {
                            detailsButton(text: detailsButtonText, proxy: proxy)
                                .padding(.bottom, 32)
                                .padding(.top, 16)
                        }
                    }
                case .contextual:
                    VStack(alignment: .leading) {
                        detailsButton(text: L10n.subscriptionPlanFeaturesInfoLink, proxy: proxy)
                        .padding(.vertical, 10)
                        contextualAnimation
                    }
            }
        }
    }

    @ViewBuilder
    func detailsButton(text: String, proxy: ScrollViewProxy) -> some View {
        Button {
            expand = true
            model.track(.plusPromotionDetailsTapped)
            withAnimation(.interpolatingSpring(stiffness: 44.44, damping: 10)) {
                proxy.scrollTo(ScrollPosition.secondPage, anchor: .top)
            }
        } label: {
            Text(text)
                .font(size: 15, style: .subheadline, weight: .medium)
                .foregroundColor(theme.primaryInteractive01)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    var pageTwo: some View {
        switch model.style {
            case .generic:
                if model.shouldShowVariation {
                    UpgradeFeaturesView(features: model.features)
                } else {
                    UpgradeTimelineView(events: model.timelineEvents)
                }
            case .contextual:
                UpgradeFeaturesView(features: model.features)
        }
    }

    func scrollableContent(proxy: ScrollViewProxy) -> some View {
        GeometryReader() { sizeProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    pageOne(proxy: proxy)
                        .frame(minHeight: model.style == .generic ? nil : sizeProxy.size.height - (Constants.gradientHeight * 2))
                    if expand, model.isFreeTrialAvailable || model.style == .contextual {
                        VStack {
                            Spacer().frame(height: 16)
                            pageTwo
                                .id(ScrollPosition.secondPage)
                            Spacer()
                        }
                        .frame(minHeight: sizeProxy.size.height - (Constants.gradientHeight * 2))
                    } else {
                        Spacer()
                            .id(ScrollPosition.secondPage)
                            .frame(height: 8)
                    }
                }
                .padding(.vertical, Constants.gradientHeight - 8)
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.visible)
            .scrollIndicatorsFlash(trigger: flash)
            .onChange(of: model.selectedProduct) { _, _ in
                if !model.isFreeTrialAvailable {
                    withAnimation {
                        expand = false
                        proxy.scrollTo(ScrollPosition.firstPage)
                    }
                }
            }
        }
    }

    var title: some View {
        HStack {
            Text(model.title)
                .font(size: 32, style: .largeTitle, weight: .bold)
                .kerning(-1)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.primaryText01)
            Spacer()
        }
    }

    @ViewBuilder
    func gradient(height: CGFloat = 16, up: Bool ) -> some View {
        Rectangle()
        .frame(height: height)
        .foregroundStyle(LinearGradient(colors: [
            theme.primaryUi01.opacity(up ? 1 : 0),
            theme.primaryUi01.opacity(up ? 0 : 1)
        ], startPoint: UnitPoint.top, endPoint: UnitPoint.bottom))
        .allowsHitTesting(false)
    }
}

#Preview {
    UpgradeAccountView(model: UpgradeAccountViewModel(flowSource: PlusLandingViewModel.Source.upsell)).setupDefaultEnvironment()
}
