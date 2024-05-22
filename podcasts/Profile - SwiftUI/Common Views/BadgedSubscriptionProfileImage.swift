import PocketCastsUtils
import PocketCastsServer
import SwiftUI

struct BadgedSubscriptionProfileImage: View {
    @ObservedObject var viewModel: ProfileHeaderViewModel
    @EnvironmentObject var theme: Theme

    var body: some View {
        content()
    }

    @ViewBuilder
    private func content() -> some View {
        VStack(spacing: 0) {
            SubscriptionProfileImage(viewModel: viewModel)
                .frame(width: Constants.imageSize, height: Constants.imageSize)

            // Show the patron badge
            if let subscription = viewModel.subscription {
                if subscription.tier == .patron {
                    SubscriptionBadge(tier: subscription.tier)
                        .padding(.top, -10)
                }

                // Display the expiration date if needed
                if subscription.expirationProgress < 1, let expirationDate = subscription.expirationDate {
                    let time = TimeFormatter.shared.appleStyleTillString(date: expirationDate) ?? L10n.timeFormatNever
                    let message = L10n.subscriptionExpiresIn(time)

                    Text(message.localizedUppercase)
                        .font(style: .caption, weight: .semibold)
                        .foregroundColor(theme.red)
                        .padding(.top, Constants.spacing)
                }
            }
        }
    }

    // MARK: - View Constants
    enum Constants {
        static let spacing = 16.0
        static let imageSize = 104.0
    }
}
