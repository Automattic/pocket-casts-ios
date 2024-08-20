import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct PlusPaywallContainer: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    @State private var presentSubscriptionView = false
    @State private var showingOverlay = false

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
            let isLoading = viewModel.priceAvailability == .loading
            Button(action: {
                guard SyncManager.isUserLoggedIn() else {
                    viewModel.presentLogin()
                    return
                }

                viewModel.loadPrices { [weak viewModel] in
                    switch viewModel?.priceAvailability {
                    case .available:
                        withAnimation {
                            showingOverlay.toggle()
                        }
                        presentSubscriptionView.toggle()
                    case .failed:
                        viewModel?.showError()
                    default:
                        break
                    }
                }
            }, label: {
                Text(L10n.upgradeExperimentPaywallButton)
            })
            .buttonStyle(PlusOpaqueButtonStyle(isLoading: isLoading, plan: .plus))
            .padding(.horizontal, Constants.buttonHPadding)

            if let offer = subscriptionInfo?.offer {
                Text(offer.experimentDescription)
                    .font(size: Constants.offerTextSize, style: .body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, Constants.offerTextTopPadding)
            }
        }
    }

    @ViewBuilder private var purchaseModal: some View {
        ZStack {
            Color(hex: PlusPurchaseModal.Config.backgroundColorHex)
                .edgesIgnoringSafeArea(.all)
            PlusPurchaseModal(coordinator: viewModel, selectedPrice: .yearly)
                .setupDefaultEnvironment()
        }
        .modify {
            if #available(iOS 16.0, *) {
                $0.presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            } else {
                $0
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

            if showingOverlay {
                Rectangle()
                    .fill(.black)
                    .opacity(0.7)
            }
        }
        .background(.black)
        .sheet(isPresented: $presentSubscriptionView, onDismiss: {
            withAnimation {
                showingOverlay.toggle()
            }
        }, content: {
            purchaseModal
        })
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

extension PlusPricingInfoModel.ProductOfferInfo {
    fileprivate var experimentDescription: String {
        switch type {
        case .freeTrial:
            return L10n.upgradeExperimentFreeMembershipFormat(duration)
        case .discount:
            return L10n.upgradeExperimentDiscountYearlyMembership
        }
    }
}

#Preview {
    PlusPaywallContainer(viewModel: PlusLandingViewModel(source: .login), type: .features)
}
