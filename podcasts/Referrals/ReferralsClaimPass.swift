import SwiftUI
import PocketCastsServer

@MainActor
class ReferralClaimPassModel: ObservableObject {
    let referralURL: URL?
    let offerInfo: ReferralsOfferInfo
    var canClaimPass: Bool
    var onClaimGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    enum State {
        case start
        case notAvailable
        case claimVerify
        case IAPPurchase
    }

    @Published var state: State

    init(referralURL: URL? = nil, offerInfo: ReferralsOfferInfo, canClaimPass: Bool = true, onClaimGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> (()))? = nil) {
        self.referralURL = referralURL
        self.offerInfo = offerInfo
        self.canClaimPass = canClaimPass
        self.onClaimGuestPassTap = onClaimGuestPassTap
        self.onCloseTap = onCloseTap
        self.state = canClaimPass ? .start : .notAvailable

        addObservers()
    }

    private func updateState(to newState: State) async {
        state = newState
    }

    private func purchaseCompleted(success: Bool) async {
        guard state == .IAPPurchase else {
            return
        }
        if success {
            state = .start
        } else {
            state = .start
        }
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapProductsFailed, object: nil, queue: .main) { [weak self] _ in
            Task {
                await self?.purchaseCompleted(success: false)
            }
        }
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapPurchaseFailed, object: nil, queue: .main) { [weak self] _ in
            Task {
                await self?.purchaseCompleted(success: false)
            }
        }
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapPurchaseCancelled, object: nil, queue: .main) { [weak self] _ in
            Task {
                await self?.purchaseCompleted(success: false)
            }
        }
        NotificationCenter.default.addObserver(forName: ServerNotifications.iapPurchaseCompleted, object: nil, queue: .main) { [weak self] _ in
            Task {
                await self?.purchaseCompleted(success: true)
            }
        }
    }

    var claimPassTitle: String {
        L10n.referralsClaimGuestPassTitle(offerInfo.localizedOfferDurationAdjective)
    }

    var claimPassDetail: String {
        L10n.referralsClaimGuestPassDetail(offerInfo.localizedPriceAfterOffer)
    }

    func claim() async {
        guard let components = referralURL?.pathComponents, let code = components.last else {
            return
        }
        guard let result = await ApiServerHandler.shared.validateCode(code) else {
            state = .notAvailable
            return
        }
        print(result.offer)
        purchase(product: IAPProductID.patronYearly)
    }

    func purchase(product: IAPProductID) {
        let purchaseHandler = IAPHelper.shared
        guard purchaseHandler.canMakePurchases else {
            state = .notAvailable
            return
        }

        guard purchaseHandler.buyProduct(identifier: product) else {
            state = .notAvailable
            return
        }

        state = .IAPPurchase
    }
}

struct ReferralClaimPassView: View {
    @StateObject var viewModel: ReferralClaimPassModel

    var body: some View {
        switch viewModel.state {
        case .start, .claimVerify, .IAPPurchase:
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
                    case .claimVerify:
                        ProgressView()
                    case .IAPPurchase:
                        ProgressView()
                    case .notAvailable:
                        ProgressView()
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
