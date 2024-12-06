import SwiftUI

struct CancelSubscriptionPlansView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var viewModel: CancelSubscriptionViewModel

    init(viewModel: CancelSubscriptionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            switch viewModel.currentProductAvailability {
            case .loading:
                showLoading()
            default:
                closeButton
                mainView
                if viewModel.state == .purchasing {
                    showLoading(fullScreen: true)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadCurrentProduct()
            }
        }
        .background(theme.primaryUi04)
    }

    var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    viewModel.closePlans()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14).weight(.bold))
                        .frame(width: 30, height: 30)
                        .foregroundColor(theme.primaryIcon02Active)
                        .background(theme.primaryUi05)
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 16.0)
            .padding(.top, 16.0)
            Spacer()
        }
    }

    var mainView: some View {
        VStack(spacing: 16.0) {
            Image("cs-app-icon")
                .frame(width: 100.0, height: 100.0)
                .padding(.top, 88.0)
                .padding(.bottom, 20.0)
            Text(L10n.cancelSubscriptionAvailablePlansTitle)
                .font(size: 28.0, style: .body, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .padding(.bottom, 24.0)
            ForEach(viewModel.pricingInfo.products, id: \.id) { product in
                CancelSubscriptionPlanRow(product: product,
                                          selected: product.identifier == viewModel.currentPricingProduct?.identifier) { selectedProduct in
                    viewModel.purchase(product: selectedProduct)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    func showLoading(fullScreen: Bool = false) -> some View {
        if fullScreen {
            ZStack {
                theme.primaryUi05Selected
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.7)
                ProgressView()
                    .tint(theme.primaryText01)
            }
        } else {
            ProgressView()
                .tint(theme.primaryUi01)
        }
    }
}

#Preview {
    CancelSubscriptionPlansView(viewModel: CancelSubscriptionViewModel(navigationController: UINavigationController()))
        .environmentObject(Theme.sharedTheme)
}
