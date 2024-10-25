import SwiftUI

struct ReferralsClaimBannerView: View {
    @EnvironmentObject var theme: Theme

    @StateObject var viewModel: ReferralClaimPassModel

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.claimPassTitle)
                        .font(size: Constants.titleSize, style: .body, weight: .bold)
                        .frame(alignment: .topLeading)
                        .foregroundStyle(theme.primaryText01)
                    Text(L10n.referralsClaimGuestPassBannerDetail)
                        .font(size: Constants.textSize, style: .body, weight: .semibold)
                        .frame(alignment: .topLeading)
                        .foregroundStyle(theme.primaryText01.opacity(0.8))
                }
                Spacer(minLength: 24)
                ReferralCardMiniView()
                    .frame(width: ReferralCardMiniView.Constants.defaultCardSize.width, height: ReferralCardMiniView.Constants.defaultCardSize.height)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(theme.primaryUi02Active)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { viewModel.onCloseTap?() }) {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .foregroundStyle(theme.secondaryIcon02)
            }
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
        .onLongPressGesture {
            viewModel.onCloseTap?()
        }
        .frame(minHeight: Constants.minHeight)
    }

    private enum Constants {
        static let opacity = 0.8
        static let titleSize = 15.0
        static let textSize = 11.0

        static let minHeight = 105.0
        static let cornerRadius = CGFloat(8)
    }
}

#Preview {
    ReferralsClaimBannerView(viewModel: ReferralClaimPassModel(referralURL: nil, coordinator: ReferralsCoordinator.shared))
            .environmentObject(Theme(previewTheme: .light))
            .previewLayout(.sizeThatFits)
            .padding(16)
            .frame(height: 105)
}
