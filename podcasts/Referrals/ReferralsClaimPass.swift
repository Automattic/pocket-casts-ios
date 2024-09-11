import SwiftUI

class ReferralClaimPassModel {
    let offerDuration: String
    var onClaimGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    init(offerDuration: String, onClaimGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> (()))? = nil) {
        self.offerDuration = offerDuration
        self.onClaimGuestPassTap = onClaimGuestPassTap
        self.onCloseTap = onCloseTap
    }

    var claimPassTitle: String {
        L10n.referralsClaimGuestPassTitle(offerDuration)
    }

    var claimPassDetail: String {
        L10n.referralsClaimGuestPassDetail("$39.99 USD")
    }
}

struct ReferralClaimPassView: View {
    let viewModel: ReferralClaimPassModel

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(L10n.eoyNotNow) {
                    viewModel.onCloseTap?()
                }
                .foregroundColor(.white)
                .font(style: .body, weight: .medium)
            }
            .padding()
            VStack(spacing: Constants.verticalSpacing) {
                SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                Text(viewModel.claimPassTitle)
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ReferralCardView(offerDuration: viewModel.offerDuration)
                    .frame(width: Constants.defaultCardSize.width, height: Constants.defaultCardSize.height)
                Text(viewModel.claimPassDetail)
                    .font(size: 13, style: .body, weight: .medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Button(L10n.referralsClaimGuestPassAction) {
                viewModel.onClaimGuestPassTap?()
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = CGSize(width: 315, height: 200)
    }
}

#Preview {
    ReferralClaimPassView(viewModel: ReferralClaimPassModel(offerDuration: "2 Months"))
}
