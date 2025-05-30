import SwiftUI

struct CancelSubscriptionOfferSuccessView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionViewModel

    var title: String {
        if viewModel.subscriptionFrequency() == .monthly {
            return L10n.cancelSubscriptionOfferSuccessViewTitle
        } else {
            return L10n.cancelSubscriptionOfferYearlySuccessViewTitle
        }
    }

    var description: String {
        if viewModel.subscriptionFrequency() == .monthly {
            return L10n.cancelSubscriptionOfferSuccessViewDescription
        } else {
            return L10n.cancelSubscriptionOfferYearlySuccessViewDescription
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                icon(for: theme.activeTheme)
                    .frame(width: 162, height: 162)
                    .padding(.top, 70)
                    .padding(.bottom, 21)
                Text(title)
                    .font(size: 28.0, style: .body, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.primaryText01)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16.0)
                Text(description)
                    .font(size: 18.0, style: .body, weight: .regular)
                    .foregroundStyle(theme.primaryText02)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
                    .frame(height: 20)
            }
            Button(action: viewModel.closeOffer) {
                Text(L10n.done)
            }
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
            .frame(minHeight: 56)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(
            AppTheme.color(for: .primaryUi01, theme: theme)
                .ignoresSafeArea()
        )
        .onDisappear {
            Analytics.track(.winbackScreenDismissed, properties: ["screen": "offer_claimed"])
        }
    }

    private func icon(for themeType: Theme.ThemeType) -> Image {
        let name: String
        switch themeType {
        case .classic, .rosé:
            name = "cs-sparkle-red"
        case .indigo:
            name = "cs-sparkle-indigo"
        case .radioactive:
            name = "cs-sparkle-green"
        case .contrastLight:
            name = "cs-sparkle-black"
        case .contrastDark:
            name = "cs-sparkle-gray"
        default:
            name = "cs-sparkle-blue"
        }
        return Image(name)
    }
}

#Preview {
    CancelSubscriptionOfferSuccessView(viewModel: CancelSubscriptionViewModel(navigationController: UINavigationController()))
        .environmentObject(Theme.sharedTheme)
}
