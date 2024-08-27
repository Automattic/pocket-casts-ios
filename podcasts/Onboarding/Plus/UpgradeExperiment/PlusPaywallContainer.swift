import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct PlusPaywallContainer: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    @State private var presentSubscriptionView = false

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
            .buttonStyle(PlusGradientFilledButtonStyle(isLoading: isLoading, plan: .plus))
            .padding(.horizontal, Constants.buttonHPadding)
            .padding(.top, Constants.buttonTopPadding)
            .frame(maxWidth: Constants.buttonmaxWidth)

            if let offer = subscriptionInfo?.offer {
                Text(offer.experimentDescription)
                    .font(size: Constants.offerTextSize, style: .body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, Constants.offerTextTopPadding)
            }
        }
        .background(Constants.backgroundColor)
    }

    @ViewBuilder private var purchaseModal: some View {
        ZStack {
            if #unavailable(iOS 16.4) {
                Constants.sheetBackgroundColor
                    .edgesIgnoringSafeArea(.all)
            }
            PlusPurchaseModal(coordinator: viewModel, selectedPrice: .yearly)
                .setupDefaultEnvironment()
        }
        .modify {
            if #available(iOS 16.0, *) {
                $0.presentationDetents([.custom(PlusPurchaseModalDetent.self)])
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
        }
        .background(Constants.backgroundColor)
        .sheet(isPresented: $presentSubscriptionView) {
            purchaseModal
                .modify {
                    if #available(iOS 16.4, *) {
                        $0.presentationBackground {
                            Constants.sheetBackgroundColor
                        }
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
            PlusPaywallFeaturesCarousell(tier: tier)
        case .reviews:
            PlusPaywallReviews(tier: .plus)
        }
    }

    enum ContainerType {
        case features
        case reviews
    }

    private enum Constants {
        static let backgroundColor = Color.black

        static let bottomPadding = 16.0

        static let offerTextSize = 14.0
        static let offerTextTopPadding = 12.0

        static let buttonHPadding = 20.0
        static let buttonTopPadding = 10.0
        static let buttonmaxWidth = 500.0

        static let sheetBackgroundColor = Color(hex: PlusPurchaseModal.Config.backgroundColorHex)
    }

    @available(iOS 16.0, *)
    struct PlusPurchaseModalDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            min(460, context.maxDetentValue)
        }
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

#Preview {
    PlusPaywallContainer(viewModel: PlusLandingViewModel(source: .login), type: .reviews)
}
