import SwiftUI

struct CancelSubscriptionView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionViewModel

    init(viewModel: CancelSubscriptionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.priceAvailability {
            case .available:
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Text(L10n.cancelSubscriptionTitle)
                            .font(size: 28.0, style: .body, weight: .bold)
                            .foregroundStyle(theme.primaryText01)
                            .multilineTextAlignment(.center)
                            .padding(.top, 48.0)
                            .padding(.horizontal, 34.0)

                        ForEach(CancelSubscriptionOption.allCases, id: \.id) { option in
                            if case .promotion = option {
                                //TODO: Need to check the if the promotion can be applied
                                if case .promotion = option, let price = viewModel.monthlyPrice() {
                                    CancelSubscriptionViewRow(option: .promotion(price: price),
                                                              viewModel: viewModel)
                                }
                            } else {
                                CancelSubscriptionViewRow(option: option,
                                                          viewModel: viewModel)
                            }
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
            case .loading, .unknown:
                ProgressView()
            case .failed:
                Text(L10n.cancelSubscriptionGenericError)
                    .font(size: 18.0, style: .body, weight: .bold)
                    .foregroundStyle(theme.primaryText01)
                    .multilineTextAlignment(.center)
            }
        }
        .background(
            color(for: .primaryUi01)
                .ignoresSafeArea()
        )
    }

    private func color(for style: ThemeStyle) -> Color {
        AppTheme.color(for: style, theme: theme)
    }
}

#Preview {
    CancelSubscriptionView(viewModel: CancelSubscriptionViewModel(navigationController: UINavigationController()))
        .environmentObject(Theme.sharedTheme)
}
