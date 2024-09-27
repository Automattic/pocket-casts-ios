import SwiftUI
import PocketCastsServer

@MainActor
class ReferralClaimPassModel {
    let referralURL: URL?
    let offerInfo: ReferralsOfferInfo
    var canClaimPass: Bool
    var onClaimGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    init(referralURL: URL? = nil, offerInfo: ReferralsOfferInfo, canClaimPass: Bool = true, onClaimGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> (()))? = nil) {
        self.referralURL = referralURL
        self.offerInfo = offerInfo
        self.canClaimPass = canClaimPass
        self.onClaimGuestPassTap = onClaimGuestPassTap
        self.onCloseTap = onCloseTap
    }

    var claimPassTitle: String {
        L10n.referralsClaimGuestPassTitle(offerInfo.localizedOfferDurationAdjective)
    }

    var claimPassDetail: String {
        L10n.referralsClaimGuestPassDetail(offerInfo.localizedPriceAfterOffer)
    }

    func claim() async {
        let code = await ApiServerHandler.shared.validateCode("test")
    }
}

struct ReferralClaimPassView: View {
    let viewModel: ReferralClaimPassModel

    var body: some View {
        if viewModel.canClaimPass {
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
                Button(L10n.referralsClaimGuestPassAction) {
                    viewModel.claim()
                }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
            }
            .padding()
            .background(.black)
        } else {
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
