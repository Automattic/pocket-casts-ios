import SwiftUI

struct CancelSubscriptionOfferSuccessView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionViewModel

    var body: some View {
        VStack(spacing: 0) {
            Image("cd-sparkle")
                .frame(width: 162, height: 162)
                .padding(.top, 70)
                .padding(.bottom, 21)
            Text(L10n.cancelSubscriptionOfferSuccessViewTitle)
                .font(size: 28.0, style: .body, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .padding(.horizontal, 12)
                .padding(.bottom, 16.0)
            Text(L10n.cancelSubscriptionOfferSuccessViewDescription)
                .font(size: 18.0, style: .body, weight: .regular)
                .foregroundStyle(theme.primaryText02)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            Button(action: viewModel.closePlans) {
                Text(L10n.done)
            }
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
            .frame(height: 56)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(
            AppTheme.color(for: .primaryUi01, theme: theme)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    CancelSubscriptionOfferSuccessView(viewModel: CancelSubscriptionViewModel(navigationController: UINavigationController()))
        .environmentObject(Theme.sharedTheme)
}
