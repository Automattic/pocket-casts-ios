import SwiftUI

struct ReferralCardView: View {
    let numberOfDaysOffered: Int

    var body: some View {
        Rectangle()
            .background {
                ReferralCardAnimatedGradientView()
            }
            .cornerRadius(Constants.cardRadius)
            .foregroundColor(.clear)
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
                    .frame(width: Constants.plusIconSize, height: Constants.plusIconSize)
                    .foregroundColor(.white)
                    .padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cardRadius)
                    .inset(by: -0.5)
                    .stroke(Constants.cardStrokeColor, lineWidth: 1)
            )
    }

    enum Constants {
        static let cardRadius = CGFloat(13)
        static let cardBackgroundColor = Color(red: 0.08, green: 0.03, blue: 0.3)
        static let cardStrokeColor = Color(red: 0.23, green: 0.23, blue: 0.23)
        static let plusIconSize = CGFloat(12)
    }
}

#Preview {
    ReferralCardView(numberOfDaysOffered: 30)
        .frame(width: 315, height: 200)
}
