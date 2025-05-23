import SwiftUI

struct CancelSubscriptionWinbackOfferView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionViewModel

    var title: String {
        guard let price = viewModel.price() else {
            return ""
        }
        if viewModel.subscriptionFrequency() == .monthly {
            return L10n.cancelSubscriptionWinbackViewTitleMontly(price)
        } else {
            return L10n.cancelSubscriptionWinbackViewTitleYearly(price)
        }
    }

    var description: String {
        guard let price = viewModel.price() else {
            return ""
        }
        if viewModel.subscriptionFrequency() == .monthly {
            return L10n.cancelSubscriptionWinbackViewDescriptionMontly
        } else {
            return L10n.cancelSubscriptionWinbackViewDescriptionYearly(price)
        }
    }

    private var loadingButton: some View {
        ZStack {
            Rectangle()
                .overlay(theme.primaryInteractive01)
                .cornerRadius(ViewConstants.buttonCornerRadius)
            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(tint: theme.primaryInteractive02)
                )
        }
        .frame(minHeight: 56.0)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    Image("cs-winback-offer")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryInteractive01)
                        .frame(width: 162, height: 162)
                        .padding(.top, 70)
                    Text(title)
                        .font(size: 28.0, style: .body, weight: .bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.primaryText01)
                        .padding(.horizontal, 18.0)
                        .padding(.bottom, 8.0)
                    Text(description)
                        .font(size: 18.0, style: .body, weight: .regular)
                        .foregroundStyle(theme.primaryText02)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            VStack(spacing: 16.0) {
                Spacer()
                    .frame(height: 16.0)
                let isLoading = viewModel.offerPurchasingState == .purchasing
                Button(action: viewModel.claimOffer) {
                    Text(L10n.cancelSubscriptionWinbackViewAcceptOfferButton)
                }
                .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
                .frame(minHeight: 56.0)
                .overlay {
                    if isLoading {
                        loadingButton
                    }
                }
                Button(action: showManageSubscriptions) {
                    Text(L10n.cancelSubscriptionWinbackViewContinueCancellationButton)
                }
                .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive01, backgroundColor: theme.primaryUi01, borderColor: theme.primaryInteractive01))
                .disabled(isLoading)
                .frame(minHeight: 56.0)
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 2.0)
        }
        .background(
            AppTheme.color(for: .primaryUi01, theme: theme)
                .ignoresSafeArea()
        )
        .onAppear {
            Analytics.track(.winbackScreenShown, properties: ["screen": "winback_offer"])
        }
    }

    private func showManageSubscriptions() {
        Analytics.track(.winbackWinbackOfferCancelButtonTapped)
        viewModel.showManageSubscriptions()
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
