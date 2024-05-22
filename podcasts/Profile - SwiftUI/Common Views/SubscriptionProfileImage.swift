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
            let content = ExpirationProgress(tier: subscription.tier, progress: subscription.expirationProgress)

            if subscription.tier == .patron {
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

        let tier: SubscriptionTier
        let progress: Double

        private var strokeColor: Color {
            switch tier {
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
    static var viewModel: ProfileHeaderViewModel {
        let viewModel = ProfileHeaderViewModel(navigationController: nil)
        viewModel.profile = UserInfo.Profile(isLoggedIn: true, email: "pinarolguc@yahoo.com", displayName: "Pinar O")
        viewModel.subscription = UserInfo.Subscription(tier: .patron, expirationProgress: 0.4, expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()))
        return viewModel
    }
    static var previews: some View {
        SubscriptionProfileImage(viewModel: viewModel)
            .frame(width: 200, height: 200)
            .setupDefaultEnvironment(theme: .init(previewTheme: .dark))
    }
}
