import SwiftUI

struct ReferralCard: View {
    let numberOfDaysOffered: Int

    var body: some View {
        Rectangle()
            .cornerRadius(13)
            .foregroundColor(Color(red: 0.08, green: 0.03, blue: 0.3))
            .overlay(alignment: .bottomLeading) {
                Text(L10n.referralsGuestPassOffer(numberOfDaysOffered))
                    .font(size: 12, style: .body, weight: .semibold)
                    .foregroundColor(.white)
                    .padding()

            }
            .overlay(alignment: .topTrailing) {
                Image("plusGold")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 12, height: 12)
                    .foregroundColor(.white)
                    .padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .inset(by: -0.5)
                    .stroke(Color(red: 0.23, green: 0.23, blue: 0.23), lineWidth: 1)
            )
    }
}

struct ReferralSendPass: View {
    let numberOfDaysOffered: Int
    let numberOfPasses: Int

    var body: some View {
        VStack {
            VStack(spacing: 24) {
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
                        ReferralCard(numberOfDaysOffered: numberOfDaysOffered)
                            .frame(width: 315.0 - (Double(numberOfPasses-1-i) * 40.0), height: 200.0)
                            .offset(CGSize(width: 0, height: Double(numberOfPasses * i) * 5.0))
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
}

#Preview {
    ReferralSendPass(numberOfDaysOffered: 30, numberOfPasses: 2)
}
