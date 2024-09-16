import SwiftUI

class ReferralSendPassModel {
    let offerInfo: ReferralsOfferInfo
    let numberOfPasses: Int
    var onShareGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    init(offerInfo: ReferralsOfferInfo, numberOfPasses: Int = 3, onShareGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> ())? = nil) {
        self.offerInfo = offerInfo
        self.numberOfPasses = numberOfPasses
        self.onShareGuestPassTap = onShareGuestPassTap
        self.onCloseTap = onCloseTap
    }

    var title: String {
        if numberOfPasses > 0 {
            L10n.referralsTipMessage(offerInfo.localizedOfferDurationNoun)
        } else {
            L10n.referralsShareNoGuestPassTitle
        }
    }

    var message: String {
        if numberOfPasses > 0 {
            L10n.referralsTipTitle(numberOfPasses)
        } else {
            L10n.referralsShareNoGuestPassMessage
        }
    }

    var buttonTitle: String {
        if numberOfPasses > 0 {
            return L10n.referralsShareGuestPass
        } else {
            return L10n.gotIt
        }
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
                Text(viewModel.message)
                    .font(size: 14, style: .body, weight: .medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ZStack {
                    ForEach(0..<viewModel.numberOfPasses, id: \.self) { i in
                        ReferralCardView(offerDuration: viewModel.offerInfo.localizedOfferDurationAdjective)
                            .frame(width: Constants.defaultCardSize.width - (CGFloat(viewModel.numberOfPasses-1-i) * Constants.cardInset.width), height: Constants.defaultCardSize.height)
                            .offset(CGSize(width: 0, height: CGFloat(viewModel.numberOfPasses * i) * Constants.cardInset.height))
                    }
                }
            }
            Spacer()
            Button(viewModel.buttonTitle) {
                if viewModel.numberOfPasses > 0 {
                    viewModel.onShareGuestPassTap?()
                } else {
                    viewModel.onCloseTap?()
                }
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = ReferralCardView.Constants.defaultCardSize
        static let cardInset = CGSize(width: 40, height: 5)
    }
}

#Preview("With Passes") {
    Group {
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerInfo: ReferralsOfferInfoMock()))
    }
}

#Preview("Without Passes") {
    Group {
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerInfo: ReferralsOfferInfoMock(), numberOfPasses: 0))
    }
}
