import SwiftUI

struct ReferralsClaimBannerView: View {
    @EnvironmentObject var theme: Theme

    let viewModel: ReferralClaimPassModel

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(L10n.referralsClaimGuestPassBannerTitle(viewModel.numberOfDaysOffered))
                        .font(size: Constants.titleSize, style: .body, weight: .bold)
                        .frame(alignment: .topLeading)
                        .foregroundStyle(theme.primaryText01)
                    Text(L10n.referralsClaimGuestPassBannerDetail)
                        .font(size: Constants.textSize, style: .body, weight: .semibold)
                        .frame(alignment: .topLeading)
                        .foregroundStyle(theme.primaryText01.opacity(0.8))
                }
                Spacer(minLength: 24)
                ReferralCardView(numberOfDaysOffered: viewModel.numberOfDaysOffered, cardRadius: Constants.cornerRadiusSmall)
                    .frame(width: 80, height: 52)
            }
            .padding()
            .background(theme.primaryUi02Active)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadiusBig))
        }
        .frame(minHeight: Constants.minHeight)
    }

    private enum Constants {
        static let opacity = 0.8
        static let titleSize = 15.0
        static let textSize = 11.0

        static let minHeight = 105.0
        static let cornerRadiusBig = 15.0
        static let cornerRadiusSmall = 4.0
    }
}

#Preview {
    ReferralsClaimBannerView(viewModel: ReferralClaimPassModel())
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
            .padding(16)
            .frame(height: 105)
}
