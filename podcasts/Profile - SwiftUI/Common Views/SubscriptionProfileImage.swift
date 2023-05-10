import SwiftUI
import PocketCastsServer

struct SubscriptionProfileImage: View {
    @ObservedObject var viewModel: ProfileDataViewModel

    var body: some View {
        ProfileImage(email: viewModel.profile.email)
            .clipShape(Circle())
            .overlay(expirationProgressView())
    }

    @ViewBuilder
    private func expirationProgressView() -> some View {
        if let subscription = viewModel.subscription {
            let content = ExpirationProgress(subscriptionType: subscription.type, progress: subscription.expirationProgress)

            if subscription.type == .patron {
                HolographicEffect(mode: .overlay) {
                    content
                }
            } else {
                content
            }
        }
    }

    private struct ExpirationProgress: View {
        @EnvironmentObject var theme: Theme

        let subscriptionType: SubscriptionType
        let progress: Double

        private var strokeColor: Color {
            switch subscriptionType {
            case .plus:
                return theme.plusPrimaryColor
            case .patron:
                return theme.patronPrimaryColor
            default:
                return .clear
            }
        }

        var body: some View {
            CircularProgressView(value: max(0.02, progress),
                                 stroke: strokeColor,
                                 strokeWidth: 4,
                                 direction: .down)
            // Outset the progress
            .padding(-5)
        }
    }
}

struct SubscriptionProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionProfileImage(viewModel: .init())
    }
}
