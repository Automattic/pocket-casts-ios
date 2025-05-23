import SwiftUI

struct ReferralCardMiniView: View {

    var body: some View {
        Rectangle()
            .background(.black)
            .foregroundColor(.black)
            .overlay {
                ReferralCardAnimatedGradientView()
            }
            .cornerRadius(Constants.cardRadius)
            .overlay(alignment: .topTrailing) {
                Image("plusGold")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Constants.plusIconSize, height: Constants.plusIconSize)
                    .foregroundColor(.white)
                    .padding(4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cardRadius)
                    .inset(by: -0.5)
                    .stroke(Constants.cardStrokeColor, lineWidth: 1)
            )
    }

    enum Constants {
        static let cardRadius = CGFloat(4)
        static let cardStrokeColor = Color(red: 0.23, green: 0.23, blue: 0.23)
        static let plusIconSize = CGFloat(6)
        static let defaultCardSize = CGSize(width: 80, height: 50)
    }
}

#Preview {
    ReferralCardMiniView()
        .frame(width: ReferralCardMiniView.Constants.defaultCardSize.width, height: ReferralCardMiniView.Constants.defaultCardSize.height)
}
