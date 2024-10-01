import SwiftUI
import PocketCastsServer
import Combine

@MainActor
class ReferralClaimPassModel: ObservableObject {
    let referralURL: URL?
    let offerInfo: ReferralsOfferInfo
    var canClaimPass: Bool
    var presentationController: UIViewController?
    var onComplete: (() -> ())?
    var onCloseTap: (() -> ())?

    enum State {
        case start
        case notAvailable
        case claimVerify
        case iapPurchase
        case signup
    }

    @Published var state: State

    init(referralURL: URL? = nil, offerInfo: ReferralsOfferInfo, canClaimPass: Bool = true, presentationController: UIViewController? = nil, onComplete: (() -> ())? = nil, onCloseTap: (() -> (()))? = nil) {
        self.referralURL = referralURL
        self.offerInfo = offerInfo
        self.canClaimPass = canClaimPass
        self.presentationController = presentationController
        self.onComplete = onComplete
        self.onCloseTap = onCloseTap
        self.state = canClaimPass ? .start : .notAvailable

        addObservers()
    }

    private var cancellables = Set<AnyCancellable>()
    private func addObservers() {
        // Observe IAP flows notification
        Publishers.Merge4(
            NotificationCenter.default.publisher(for: ServerNotifications.iapProductsFailed),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseFailed),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseCancelled),
            NotificationCenter.default.publisher(for: ServerNotifications.iapPurchaseCompleted)
        )
        .receive(on: OperationQueue.main)
        .sink { [unowned self] notification in
            Task {
                await purchaseCompleted(success: notification.name == ServerNotifications.iapPurchaseCompleted)
            }
        }
        .store(in: &cancellables)

        //Observe Login/Signup notification
        NotificationCenter.default.publisher(for: .onboardingFlowDidDismiss)
        .receive(on: OperationQueue.main)
        .sink { [unowned self] notification in
            Task {
                await refreshStatusAfterLogin()
            }
        }
        .store(in: &cancellables)
    }

    var claimPassTitle: String {
        L10n.referralsClaimGuestPassTitle(offerInfo.localizedOfferDurationAdjective)
    }

    var claimPassDetail: String {
        L10n.referralsClaimGuestPassDetail(offerInfo.localizedPriceAfterOffer)
    }

    func refreshStatusAfterLogin() async {
        if state == .signup {
            if SyncManager.isUserLoggedIn() {
                await claim()
            } else {
                Toast.show(L10n.referralsClaimNeedToBeLoggedin)
                state = .start
            }
        }
    }

    func claim() async {
        guard let components = referralURL?.pathComponents, let code = components.last else {
            return
        }
        if !SyncManager.isUserLoggedIn() {
            signup()
            state = .signup
            return
        }

        state = .claimVerify
        guard let result = await ApiServerHandler.shared.validateCode(code) else {
            Settings.referralURL = nil
            state = .notAvailable
            return
        }
        guard let productToBuy = translateToProduct(offer: result) else {
            state = .notAvailable
            return
        }
        purchase(product: productToBuy)
    }

    private func signup() {
        let onboardVC = OnboardingFlow.shared.begin(flow: .referralCode)

        presentationController?.present(onboardVC, animated: true)
    }

    private func translateToProduct(offer: ReferralValidate) -> IAPProductID? {
        if offer.offer == "two_months_free" {
            return IAPProductID.patronYearly
        }
        return nil
    }

    private func purchase(product: IAPProductID) {
        let purchaseHandler = IAPHelper.shared
        guard purchaseHandler.canMakePurchases else {
            state = .notAvailable
            return
        }

        guard purchaseHandler.buyProduct(identifier: product) else {
            state = .notAvailable
            return
        }

        state = .iapPurchase
    }

    private func purchaseCompleted(success: Bool) async {
        guard state == .iapPurchase else {
            return
        }
        if success {
            await redeemCode()
            Settings.referralURL = nil
            onComplete?()
        } else {
            state = .start
        }
    }

    private func redeemCode() async {
        guard let components = referralURL?.pathComponents, let code = components.last else {
            return
        }
        let result = await ApiServerHandler.shared.redeemCode(code)

        if result {
            onComplete?()
            return
        } else {
            state = .start
        }
    }
}

struct ReferralClaimPassView: View {
    @StateObject var viewModel: ReferralClaimPassModel

    @ViewBuilder
    var loadingIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .black))
    }

    var body: some View {
        switch viewModel.state {
        case .start, .claimVerify, .iapPurchase, .signup:
            VStack {
                HStack {
                    Spacer()
                    Button(L10n.eoyNotNow) {
                        viewModel.onCloseTap?()
                    }
                    .foregroundColor(.white)
                    .font(style: .body, weight: .medium)
                }
                .padding()
                VStack(spacing: Constants.verticalSpacing) {
                    SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                    Text(viewModel.claimPassTitle)
                        .font(size: 31, style: .title, weight: .bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    ReferralCardView(offerDuration: viewModel.offerInfo.localizedOfferDurationAdjective)
                        .frame(width: Constants.defaultCardSize.width, height: Constants.defaultCardSize.height)
                    Text(viewModel.claimPassDetail)
                        .font(size: 13, style: .body, weight: .medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.claim()
                    }
                }, label: {
                    switch viewModel.state {
                    case .start:
                        Text(L10n.referralsClaimGuestPassAction)
                    case .claimVerify, .iapPurchase, .notAvailable, .signup:
                        loadingIndicator
                    }
                })
                .buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
            }
            .padding()
            .background(.black)
        case .notAvailable:
            ReferralsMessageView(title: L10n.referralsOfferNotAvailableTitle,
                                 detail: L10n.referralsOfferNotAvailableDetail) {
                viewModel.onCloseTap?()
            }
        }
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = CGSize(width: 315, height: 200)
    }
}

#Preview {
    ReferralClaimPassView(viewModel: ReferralClaimPassModel(referralURL: nil, offerInfo: ReferralsOfferInfoMock(), canClaimPass: true))
}
