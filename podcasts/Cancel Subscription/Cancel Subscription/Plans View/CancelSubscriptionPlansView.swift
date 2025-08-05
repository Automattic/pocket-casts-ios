import SwiftUI

struct CancelSubscriptionPlansView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionPlansViewModel
    @Environment(\.sizeCategory) private var sizeCategory

    private var bottomPadding: CGFloat {
        max(16.0, 16.0 * ScaleFactorModifier.scaleFactor(for: sizeCategory))
    }

    init(viewModel: CancelSubscriptionPlansViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        makeMainView()
        .onAppear {
            loadProducts()
        }
        .background(theme.primaryUi01)
    }

    var plansView: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("cs-app-icon")
                    .frame(width: 80.0, height: 80.0)
                    .padding(.top, 88.0)
                    .padding(.bottom, 16.0)
                Text(L10n.cancelSubscriptionAvailablePlansTitle)
                    .font(size: 28.0, style: .body, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.primaryText01)
                    .padding(.bottom, 28.0)
                ForEach(viewModel.getOrderedProducts(), id: \.id) { product in
                    CancelSubscriptionPlanRow(product: product,
                                              selected: product.identifier == viewModel.currentPricingProduct?.identifier) { selectedProduct in
                        viewModel.purchase(product: selectedProduct)
                    }
                                              .padding(.bottom, bottomPadding)
                }
                Text(L10n.cancelSubscriptionAvailablePlansFooter)
                    .font(size: 14.0, style: .body, weight: .regular)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.primaryText02)
                    .padding(.horizontal, 56.0)
                Spacer()
            }
        }
    }

    var retryView: some View {
        VStack(spacing: 0) {
            Image("cs-yield")
                .renderingMode(.template)
                .foregroundStyle(theme.primaryIcon03)
                .frame(width: 40.0, height: 40.0)
                .padding(.top, 240.0)
                .padding(.bottom, 16.0)
            Text(L10n.cancelSubscriptionAvailablePlansRetryScreenText)
                .font(size: 15.0, style: .body, weight: .medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText01)
                .padding(.bottom, 16.0)
            Button(action: loadProducts) {
                Text(L10n.tryAgain)
                    .font(size: 15.0, style: .body, weight: .regular)
                    .foregroundStyle(theme.primaryText01)
                    .frame(height: 28.0)
                    .padding(.horizontal, 16.0)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 14.0,
                            style: .continuous
                        )
                        .fill(theme.primaryInteractive03)
                    )
            }
            Spacer()
        }
        .padding(.horizontal, 46)
    }

    @ViewBuilder func makeMainView() -> some View {
        switch viewModel.currentProductAvailability {
        case .loading, .idle:
            showLoading()
        case .unavailable:
            retryView
                .frame(maxWidth: .infinity)
        case .available:
            ZStack {
                plansView
                VStack {
                    HStack {
                        Button(action: viewModel.popViewController) {
                            Image(systemName: "chevron.left")
                                .renderingMode(.template)
                                .font(.system(size: 20))
                                .foregroundStyle(theme.primaryIcon01)
                                .frame(width: 32, height: 32)
                        }
                        .padding(.leading, 8)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 20)
                if viewModel.state == .purchasing {
                    showLoading(fullScreen: true)
                }
            }
        }
    }

    @ViewBuilder
    func showLoading(fullScreen: Bool = false) -> some View {
        if fullScreen {
            ZStack {
                theme.primaryUi05Selected
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.4)
                ProgressView()
                    .tint(theme.primaryText01)
            }
        } else {
            ProgressView()
                .tint(theme.primaryText01)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadProducts() {
        Task {
            await viewModel.loadCurrentProduct()
        }
    }
}

#Preview {
    CancelSubscriptionPlansView(viewModel: CancelSubscriptionPlansViewModel(navigationController: UINavigationController()))
        .environmentObject(Theme.sharedTheme)
}
