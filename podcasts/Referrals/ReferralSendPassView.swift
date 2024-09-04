import SwiftUI

class ReferralSendPassModel {
    let numberOfDaysOffered: Int
    let numberOfPasses: Int
    var onShareGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?
    
    init(numberOfDaysOffered: Int = 30, numberOfPasses: Int = 3, onShareGuestPassTap: (() -> ())? = nil) {
        self.numberOfDaysOffered = numberOfDaysOffered
        self.numberOfPasses = numberOfPasses
        self.onShareGuestPassTap = nil
    }
}

struct ReferralSendPassView: View {
    let viewModel: ReferralSendPassModel

    var body: some View {
        VStack {
            ModalCloseButton(background: Color.gray.opacity(0.2), foreground: Color.white.opacity(0.5), action: { viewModel.onCloseTap?() })
            VStack(spacing: Constants.verticalSpacing) {
                SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                Text(L10n.referralsTipMessage(viewModel.numberOfDaysOffered))
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Text(L10n.referralsTipTitle(viewModel.numberOfPasses))
                    .font(size: 14, style: .body, weight: .medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ZStack {
                    ForEach(0..<viewModel.numberOfPasses, id: \.self) { i in
                        ReferralCardView(numberOfDaysOffered: viewModel.numberOfDaysOffered)
                            .frame(width: Constants.defaultCardSize.width - (CGFloat(viewModel.numberOfPasses-1-i) * Constants.cardInset.width), height: Constants.defaultCardSize.height)
                            .offset(CGSize(width: 0, height: CGFloat(viewModel.numberOfPasses * i) * Constants.cardInset.height))
                    }
                }
            }
            Spacer()
            Button(L10n.referralsShareGuestPass) {
                viewModel.onShareGuestPassTap?()
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = CGSize(width: 315, height: 200)
        static let cardInset = CGSize(width: 40, height: 5)
    }
}

#Preview {
    ReferralSendPassView(viewModel: ReferralSendPassModel())
}
