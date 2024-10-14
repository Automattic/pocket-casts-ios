import SwiftUI
import PocketCastsServer
import Combine

@MainActor
class ReferralClaimPassModel: ObservableObject {
    let referralURL: URL?
    let coordinator: ReferralsCoordinator
    var canClaimPass: Bool
    var presentationController: UIViewController?
    var onComplete: (() -> ())?
    var onCloseTap: (() -> ())?

    enum State {
        case loading
        case start
        case notAvailable
        case claimVerify
        case iapPurchase
        case signup
    }

    @Published var state: State

    init(referralURL: URL? = nil, coordinator: ReferralsCoordinator = ReferralsCoordinator.shared, canClaimPass: Bool = true, presentationController: UIViewController? = nil, onComplete: (() -> ())? = nil, onCloseTap: (() -> (()))? = nil) {
        self.referralURL = referralURL
        self.coordinator = coordinator
        self.canClaimPass = canClaimPass
        self.presentationController = presentationController
        self.onComplete = onComplete
        self.onCloseTap = onCloseTap
        self.state = canClaimPass ? .loading : .notAvailable

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

        //Observe Login/Signup notification
        NotificationCenter.default.publisher(for: ServerNotifications.iapProductsUpdated)
        .receive(on: OperationQueue.main)
        .sink { [unowned self] notification in
            Task {
                await loadOfferInfo()
            }
        }
        .store(in: &cancellables)
    }

    var claimPassTitle: String {
        guard let referralsOfferInfo = coordinator.referralsOfferInfo else {
            return L10n.none
        }
        return L10n.referralsClaimGuestPassTitle(referralsOfferInfo.localizedOfferDurationAdjective)
    }

    var claimPassDetail: String {
        guard let referralsOfferInfo = coordinator.referralsOfferInfo else {
            return L10n.none
        }
        return L10n.referralsClaimGuestPassDetail(referralsOfferInfo.localizedPriceAfterOffer)
    }

    var offerDuration: String {
        guard let referralsOfferInfo = coordinator.referralsOfferInfo else {
            return L10n.none
        }
        return referralsOfferInfo.localizedOfferDurationAdjective
    }

    func loadOfferInfo(firstTime: Bool = false) async {
        guard coordinator.referralsOfferInfo != nil else {
            if firstTime {
                IAPHelper.shared.requestProductInfoIfNeeded()
            } else {
                state = .notAvailable
            }
            return
        }

        state = .start
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
        Analytics.track(.referralActivateTapped)

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
            coordinator.cleanReferalURL()
            state = .notAvailable
            return
        }

        purchase(offer: result)
    }

    private func signup() {
        let onboardVC = OnboardingFlow.shared.begin(flow: .referralCode)

        presentationController?.present(onboardVC, animated: true)
    }

    private func purchase(offer: ReferralValidate) {
        Analytics.track(.referralPurchaseShown)

        let coordinator = ReferralsCoordinator.shared

        guard coordinator.purchase(offer: offer) else {
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
            Analytics.track(.referralPurchaseSuccess)
            await redeemCode()
            coordinator.cleanReferalURL()
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
        case .loading:
            loadingIndicator
            .onAppear() {
                Task {
                    await viewModel.loadOfferInfo(firstTime: true)
                }
            }

        case .start, .claimVerify, .iapPurchase, .signup:
            VStack {
                HStack {
                    Spacer()
                    Button(L10n.eoyNotNow) {
                        Analytics.track(.referralNotNowTapped)
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
                    ReferralCardView(offerDuration: viewModel.offerDuration)
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
                    case .claimVerify, .iapPurchase, .notAvailable, .signup, .loading:
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
                Analytics.track(.referralUsedScreenShown)
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
    ReferralClaimPassView(viewModel: ReferralClaimPassModel(referralURL: nil, coordinator: ReferralsCoordinator.shared, canClaimPass: true))
}
