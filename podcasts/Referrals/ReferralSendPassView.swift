import SwiftUI

class ReferralSendPassModel {
    let offerDuration: String
    let numberOfPasses: Int
    var onShareGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    init(offerDuration: String, numberOfPasses: Int = 3, onShareGuestPassTap: (() -> ())? = nil) {
        self.offerDuration = offerDuration
        self.numberOfPasses = numberOfPasses
        self.onShareGuestPassTap = nil
    }

    var title: String {
        if numberOfPasses > 0 {
            L10n.referralsTipMessage(offerDuration)
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
                        ReferralCardView(offerDuration: viewModel.offerDuration)
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
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerDuration: "2 months"))
    }
}

#Preview("Without Passes") {
    Group {
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerDuration: "2 months", numberOfPasses: 0))
    }
}
