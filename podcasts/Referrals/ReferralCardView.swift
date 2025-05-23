import SwiftUI

struct ReferralCardView: View {
    let offerDuration: String

    init(offerDuration: String) {
        self.offerDuration = offerDuration
    }

    var body: some View {
        Rectangle()
            .foregroundColor(.black)
            .background(.black)
            .overlay {
                ReferralCardAnimatedGradientView()
            }
            .overlay(alignment: .bottomLeading) {
                Text(L10n.referralsGuestPassOffer(offerDuration))
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
                    .stroke(Constants.cardStrokeColor)
            )
            .cornerRadius(Constants.cardRadius)
    }

    enum Constants {
        static let cardRadius = CGFloat(13)
        static let cardStrokeColor = Color(red: 0.23, green: 0.23, blue: 0.23)
        static let plusIconSize = CGFloat(12)
        static let defaultCardSize = CGSize(width: 315, height: 200)
    }
}

#Preview {
    HStack {
        ReferralCardView(offerDuration: "2-Month")
            .frame(width: 315, height: 200)
    }
    .background(.white)
}
