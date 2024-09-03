import SwiftUI

struct ReferralCard: View {

    var body: some View {
        Rectangle()
            .frame(width: 315, height: 200)
            .cornerRadius(13)
            .foregroundColor(Color(red: 0.08, green: 0.03, blue: 0.3))
            .overlay(alignment: .bottomLeading) {
                Text("30-Day Guest Pass")
                    .font(size: 12, style: .body, weight: .semibold)
                    .foregroundColor(.white)
                    .padding()

            }
            .overlay(alignment: .topTrailing) {
                Text("+")
                    .font(size: 12, style: .body, weight: .semibold)
                    .foregroundColor(.white)
                    .padding()
            }
    }
}

struct ReferralSendPass: View {
    var body: some View {
        VStack {
            VStack(spacing: 24) {
                Button("Plus") {

                }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
                Text(L10n.referralsTipMessage(30))
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Text(L10n.referralsTipTitle(3))
                    .font(size: 14, style: .body, weight: .medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ZStack {
                    ReferralCard()
                }
            }
            Spacer()
            Button("Share Guest Pass") {

            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
    }
}

#Preview {
    ReferralSendPass()
}
