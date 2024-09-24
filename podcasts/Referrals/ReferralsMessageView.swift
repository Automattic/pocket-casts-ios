import Foundation
import SwiftUI

struct ReferralsMessageView: View {
    let title: String
    let detail: String
    let onDismiss: (() -> ())?

    var body: some View {
        VStack {
            VStack(spacing: Constants.verticalSpacing) {
                SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                Text(title)
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Text(detail)
                    .font(size: 14, style: .body, weight: .medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(L10n.gotIt) {
                onDismiss?()
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
    }
}

#Preview {
    ReferralsMessageView(title: L10n.referralsOfferNotAvailableTitle,
                        detail: L10n.referralsOfferNotAvailableDetail,
                        onDismiss: nil)
}
