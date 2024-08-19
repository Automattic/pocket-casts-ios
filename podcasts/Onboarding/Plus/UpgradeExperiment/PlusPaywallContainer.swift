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
                Text("Get Pocket Casts Plus")
            })
            .buttonStyle(PlusOpaqueButtonStyle(isLoading: false, plan: .plus))
            .padding(.horizontal, 20)

            if let offer = subscriptionInfo?.offer {
                Text(offer.title)
                    .font(size: 14.0, style: .body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, 12)
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
            .padding(.bottom, hasBottomSafeArea ? 0 : 16)
        }
        .background(.black)
        .sheet(isPresented: $presentSubscriptionView) {
            Rectangle()
                .fill(Color(hex: "282829"))
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
}

#Preview {
    PlusPaywallContainer(viewModel: PlusLandingViewModel(source: .login), type: .features)
}
