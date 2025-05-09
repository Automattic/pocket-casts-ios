import SwiftUI

struct CancelSubscriptionView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionViewModel

    private let rows: [CancelSubscriptionOption] = [.availablePlans, .help]

    init(viewModel: CancelSubscriptionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                switch (viewModel.priceAvailability, viewModel.offerLoadingState) {
                case (.available, .loaded):
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Text(L10n.cancelSubscriptionTitle)
                                .font(size: 28.0, style: .body, weight: .bold)
                                .foregroundStyle(theme.primaryText01)
                                .multilineTextAlignment(.center)
                                .padding(.top, 48.0)
                                .padding(.horizontal, 34.0)

                            ForEach(rows, id: \.id) { option in
                                CancelSubscriptionViewRow(option: option,
                                                          viewModel: viewModel)
                            }
                        }
                    }

                    Button(action: {
                        viewModel.cancelSubscriptionTap()
                    }, label: {
                        Text(L10n.cancelSubscriptionContinueButton)
                            .font(size: 18.0, style: .body, weight: .bold)
                            .foregroundStyle(theme.primaryText01)
                            .multilineTextAlignment(.center)
                    })
                    .padding(.horizontal, 34.0)
                    .padding(.top, 10.0)
                    .padding(.bottom, 58.0)
                case (.failed, _):
                    Text(L10n.cancelSubscriptionGenericError)
                        .font(size: 18.0, style: .body, weight: .bold)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.center)
                default:
                    ProgressView()
                        .tint(theme.primaryText01)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            if viewModel.offerPurchasingState == .purchasing {
                ZStack {
                    theme.primaryUi05Selected
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.4)
                    ProgressView()
                        .tint(theme.primaryText01)
                }
            }
        }
        .background(
            color(for: .primaryUi01)
                .ignoresSafeArea()
        )
        .task {
            await viewModel.loadWinbackOffer()
        }
    }

    private func color(for style: ThemeStyle) -> Color {
        AppTheme.color(for: style, theme: theme)
    }
}

#Preview {
    CancelSubscriptionView(viewModel: CancelSubscriptionViewModel(navigationController: UINavigationController()))
        .environmentObject(Theme.sharedTheme)
}
