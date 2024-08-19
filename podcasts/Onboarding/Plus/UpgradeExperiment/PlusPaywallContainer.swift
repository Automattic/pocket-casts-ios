import SwiftUI
import PocketCastsUtils

struct PlusPaywallContainer: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    @State var presentSubscriptionView = false

    private let type: ContainerType
    private let subscriptionInfo: PlusPricingInfoModel.PlusProductPricingInfo?
    private let tier = UpgradeTier.plus

    private var hasBottomSafeArea: Bool {
        !UIDevice.current.isiPad() && safeAreaBottomHeight > 0
    }

    private var safeAreaBottomHeight: CGFloat {
        (SceneHelper.connectedScene()?.windows.first(where: \.isKeyWindow)?.safeAreaInsets.bottom ?? 0)
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Spacer()
            Button(viewModel.source == .upsell ? L10n.eoyNotNow : L10n.plusSkip) {
                viewModel.dismissTapped()
            }
            .foregroundColor(.white)
            .font(style: .body, weight: .medium)
            .padding()
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Button(action: {
                presentSubscriptionView.toggle()
            }, label: {
                Text(L10n.upgradeExperimentPaywallButton)
            })
            .buttonStyle(PlusOpaqueButtonStyle(isLoading: false, plan: .plus))
            .padding(.horizontal, Constants.buttonHPadding)

            if let offer = subscriptionInfo?.offer {
                Text(offer.title)
                    .font(size: Constants.offerTextSize, style: .body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, Constants.offerTextTopPadding)
            }
        }
    }

    init(viewModel: PlusLandingViewModel, type: ContainerType) {
        self.viewModel = viewModel
        self.type = type

        let displayProduct = [viewModel.continuePurchasing, viewModel.initialProduct].compactMap { $0 }.first

        self.subscriptionInfo = viewModel.pricingInfo(for: tier, frequency: displayProduct?.frequency ?? .yearly)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                Spacer()
                container()
                Spacer()
                footer
            }
            .padding(.bottom, hasBottomSafeArea ? 0 : Constants.bottomPadding)
        }
        .background(.black)
        .sheet(isPresented: $presentSubscriptionView) {
            PlusPaywallSubscriptions(viewModel: viewModel)
                .modify {
                    if #available(iOS 16.0, *) {
                        $0.presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    } else {
                        $0
                    }
                }
        }
    }

    @ViewBuilder
    private func container() -> some View {
        switch type {
        case .features:
            PlusPaywallFeaturesCarousell(viewModel: viewModel, tier: tier)
        case .social:
            Rectangle()
                .fill(.yellow)
        }
    }

    enum ContainerType {
        case features
        case social
    }

    private enum Constants {
        static let bottomPadding = 16.0

        static let offerTextSize = 14.0
        static let offerTextTopPadding = 12.0

        static let buttonHPadding = 20.0
    }
}

#Preview {
    PlusPaywallContainer(viewModel: PlusLandingViewModel(source: .login), type: .features)
}
