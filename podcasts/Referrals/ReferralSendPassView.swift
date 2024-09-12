import SwiftUI

class ReferralSendPassModel {
    let offerInfo: ReferralsOfferInfo
    var onShareGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    init(offerInfo: ReferralsOfferInfo, onShareGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> ())? = nil) {
        self.offerInfo = offerInfo
        self.onShareGuestPassTap = onShareGuestPassTap
        self.onCloseTap = onCloseTap
    }

    var title: String {
        L10n.referralsTipMessage(offerInfo.localizedOfferDurationNoun)
    }

    var buttonTitle: String {
        L10n.referralsShareGuestPass
    }
}

struct ReferralSendPassView: View {
    let viewModel: ReferralSendPassModel

    var body: some View {
        VStack {
            ModalCloseButton(background: Color.gray.opacity(0.2), foreground: Color.white.opacity(0.5), action: { viewModel.onCloseTap?() })
            VStack(spacing: Constants.verticalSpacing) {
                SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                Text(viewModel.title)
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ZStack {
                    ForEach(0..<Constants.numberOfPasses, id: \.self) { i in
                        ReferralCardView(offerDuration: viewModel.offerInfo.localizedOfferDurationAdjective)
                            .frame(width: Constants.defaultCardSize.width - (CGFloat(Constants.numberOfPasses-1-i) * Constants.cardInset.width), height: Constants.defaultCardSize.height)
                            .offset(CGSize(width: 0, height: CGFloat(Constants.numberOfPasses * i) * Constants.cardInset.height))
                    }
                }
            }
            Spacer()
            Button(viewModel.buttonTitle) {
                viewModel.onShareGuestPassTap?()
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = ReferralCardView.Constants.defaultCardSize
        static let cardInset = CGSize(width: 40, height: 5)
        static let numberOfPasses: Int = 3
    }
}

#Preview("With Passes") {
    Group {
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerInfo: ReferralsOfferInfoMock()))
    }
}
