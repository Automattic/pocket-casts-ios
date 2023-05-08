import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct AccountHeaderView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: AccountHeaderViewModel

    var body: some View {
        container { proxy in
            SubscriptionProfileImage(viewModel: viewModel)
                .frame(width: Constants.imageSize, height: Constants.imageSize)

            ProfileInfoLabels(profile: viewModel.profile, alignment: .center, spacing: Constants.spacing)
                .padding(.top, 5)

            VStack {
                // Subscription badge
                viewModel.subscription.map {
                    SubscriptionBadge(type: $0.type)
                        .padding(.bottom, 10)
                }

                // Subscription details labels
                HStack {
                    let (title, label) = subscriptionLabels

                    Text(title)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    label
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(theme.primaryText01)
                .font(size: 14, style: .subheadline, weight: .medium)
            }
        }
    }

    private var subscriptionLabels: (String, Text?) {
        switch viewModel.viewState {
        case .freeAccount:
            // Show the free account status and the total listening time the user has
            return (
                L10n.accountDetailsFreeAccount,
                viewModel.stats.listeningTime.seconds.localizedTimeDescription.map {
                    Text(L10n.accountDetailsListenedFor($0))
                }
            )
        case .activeSubscription(_, let frequency, let expirationDate):
            // Show the next billing date, and how often their subscription reviews
            return (
                L10n.nextPaymentFormat(DateFormatHelper.sharedHelper.longLocalizedFormat(expirationDate)),
                frequency.localizedDescription.map { Text($0) }
            )
        case .freeTrial(let remaining):
            // Show the time remaining in the free trial and the date it expires
            return (
                L10n.plusFreeMembershipFormat(DateFormatHelper.sharedHelper.shortTimeRemaining(remaining).localizedCapitalized),
                expirationLabel()
            )
        case .lifetime:
            // Lifetime membership, show a thank you message
            return (
                L10n.subscriptionsThankYou,
                Text(L10n.plusLifetimeMembership)
                    .foregroundColor(theme.green)
            )
        case .paymentCancelled:
            // Show the cancelled label, and the date the subscription expires
            return (
                L10n.plusPaymentCanceled,
                expirationLabel()
            )
        }
    }

    private func expirationLabel() -> Text? {
        guard
            let expirationDate = viewModel.subscription?.expirationDate,
            let expirationProgress = viewModel.subscription?.expirationProgress
        else {
            return nil
        }

        // If we're more than the max days (progress >= 1) then show the expirationd ate
        guard expirationProgress < 1 else {
            let label = L10n.plusExpirationFormat(DateFormatHelper.sharedHelper.longLocalizedFormat(expirationDate))
            return Text(label)
        }

        // Less than the max days (30 days) show the expires in time
        return TimeFormatter.shared.appleStyleTillString(date: expirationDate).map {
            Text(L10n.subscriptionExpiresIn($0))
                .foregroundColor(theme.red)
        }
    }

    // MARK: - Private: Wrapper Views
    @ViewBuilder
    /// Main content wrapper view that renders the rest of the content
    private func container<Content: View>(@ViewBuilder _ content: @escaping (GeometryProxy) -> Content) -> some View {
        ContentSizeGeometryReader { proxy in
            VStack(spacing: Constants.spacing) {
                content(proxy)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        } contentSizeUpdated: { size in
            viewModel.contentSizeChanged(size)
        }
    }

    // MARK: - View Constants
    private enum Constants {
        static let spacing = 16.0
        static let imageSize = 64.0
    }
}

// MARK: - SubscriptionFrequency Helper Extension
private extension SubscriptionFrequency {
    var localizedDescription: String? {
        switch self {
        case .none:
            return nil
        case .monthly:
            return L10n.monthly
        case .yearly:
            return L10n.yearly
        }
    }
}

// MARK: - Previews
struct AccountHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AccountHeaderView(viewModel: .init())

            Spacer()
        }.setupDefaultEnvironment()
    }
}
