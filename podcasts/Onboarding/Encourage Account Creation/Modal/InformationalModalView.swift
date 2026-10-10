import SwiftUI
import PocketCastsUtils

struct InformationalModalView: View {
    @EnvironmentObject var theme: Theme
    @State var currentIndex: Int? = 0

    let viewModel: InformationalModalViewModel
    let isFormSheet: Bool

    private let items = InformationalFeatureCardItem.allCases
    private var cardHeight: CGFloat {
        isFormSheet ? 274 : 370
    }

    var body: some View {
        VStack(spacing: 0) {
            labels
            Spacer()
                .frame(
                    minHeight: isFormSheet ? 24.0 : 15.0,
                    maxHeight: isFormSheet ? 24.0 : 37.0
                )
            GeometryReader { proxy in
                HorizontalCarouselCardViewContainer(
                    spacing: isFormSheet ? 18.0 : 16.0,
                    items: items,
                    currentIndex: $currentIndex,
                    cardSize: CGSize(
                        width: isFormSheet ? 400 : proxy.size.width - 48.0,
                        height: cardHeight
                    ),
                    hPadding: isFormSheet ? (proxy.size.width - 400) * 0.5 : 24.0,
                    showPagination: true,
                    paginationColor: theme.primaryText01,
                    isFormSheet: isFormSheet
                )
            }
            .frame(maxHeight: cardHeight + 24.0)
            buttons
                .padding(.top, isFormSheet ? 12.0 : 33.0)
                .if(!isFormSheet) {
                    $0.padding(.horizontal, 24.0)
                }
                .if(isFormSheet) {
                    $0.frame(maxWidth: 400)
                }
        }
        .background(theme.primaryUi01.ignoresSafeArea())
        .onChange(of: currentIndex ?? 0) { _, newValue in
            viewModel.pageDidChange(newValue)
        }
    }

    private var labels: some View {
        VStack(spacing: 0) {
            Text(L10n.eacInformationalViewModalTitle)
                .font(size: 22, style: .body, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .multilineTextAlignment(.center)
                .padding(.top, isFormSheet ? 0 : 20.0)
                .padding(.bottom, 12.0)
            Text(L10n.eacInformationalViewModalDescription)
                .font(size: 15, style: .body, weight: .medium)
                .foregroundStyle(theme.primaryText02)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24.0)
    }

    private var buttons: some View {
        VStack(spacing: 0) {
            Button(L10n.createAccount) {
                viewModel.getStarted()
            }
            .buttonStyle(RoundedButtonStyle(theme: theme))
            .padding(.bottom, 16.0)

            Button(L10n.accountLogin) {
                viewModel.login()
            }
            .buttonStyle(SimpleTextButtonStyle(theme: theme))
        }
    }
}

#Preview {
    InformationalModalView(viewModel: InformationalModalViewModel(), isFormSheet: false)
        .environmentObject(Theme(previewTheme: .light))
}
