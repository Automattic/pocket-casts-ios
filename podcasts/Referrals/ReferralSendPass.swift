import SwiftUI

struct ReferralSendPass: View {
    let numberOfDaysOffered: Int
    let numberOfPasses: Int

    var body: some View {
        VStack {
            VStack(spacing: Constants.verticalSpacing) {
                SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                Text(L10n.referralsTipMessage(numberOfDaysOffered))
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Text(L10n.referralsTipTitle(numberOfPasses))
                    .font(size: 14, style: .body, weight: .medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ZStack {
                    ForEach(0..<numberOfPasses, id: \.self) { i in
                        ReferralCardView(numberOfDaysOffered: numberOfDaysOffered)
                            .frame(width: Constants.defaultCardSize.width - (CGFloat(numberOfPasses-1-i) * Constants.cardInset.width), height: Constants.defaultCardSize.height)
                            .offset(CGSize(width: 0, height: CGFloat(numberOfPasses * i) * Constants.cardInset.height))
                    }
                }
            }
            Spacer()
            Button(L10n.referralsShareGuestPass) {

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
    ReferralSendPass(numberOfDaysOffered: 30, numberOfPasses: 2)
}
