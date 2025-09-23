import SwiftUI
import PocketCastsUtils

struct InformationalModalView: View {
    @EnvironmentObject var theme: Theme
    @State var currentIndex: Int? = 0

    let viewModel: InformationalModalViewModel

    private let items = InformationalFeatureCardItem.allCases
    private var isiPad: Bool {
        UIDevice.current.isiPad()
    }
    private var cardHeight: CGFloat {
        isiPad ? 274 : 370
    }

    var body: some View {
        VStack(spacing: 0) {
            labels
            Spacer()
                .frame(
                    minHeight: isiPad ? 24.0 : 15.0,
                    maxHeight: isiPad ? 24.0 : 37.0
                )
            GeometryReader { proxy in
                HorizontalCarouselCardViewContainer(
                    spacing: isiPad ? 18.0 : 16.0,
                    items: items,
                    currentIndex: $currentIndex,
                    cardSize: CGSize(
                        width: isiPad ? 400 : proxy.size.width - 48.0,
                        height: cardHeight
                    ),
                    hPadding: isiPad ? (proxy.size.width - 400) * 0.5 : 24.0,
                    showPagination: true,
                    paginationColor: theme.primaryText01
                )
            }
            .frame(maxHeight: cardHeight + 24.0)
            buttons
                .padding(.top, isiPad ? 12.0 : 33.0)
                .if(!isiPad) {
                    $0.padding(.horizontal, 24.0)
                }
                .if(isiPad) {
                    $0.frame(maxWidth: 400)
                }
        }
        .background(theme.primaryUi01.ignoresSafeArea())
        .onChange(of: currentIndex ?? 0) { newValue in
            viewModel.pageDidChange(newValue)
        }
    }

    private var labels: some View {
        VStack(spacing: 0) {
            Text(L10n.eacInformationalViewModalTitle)
                .font(size: 22, style: .body, weight: .bold)
                .foregroundStyle(theme.primaryText01)
                .multilineTextAlignment(.center)
                .padding(.top, isiPad ? 0 : 20.0)
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
            Button(FeatureFlag.newOnboardingAccountCreation.enabled ? L10n.createAccount : L10n.eacInformationalViewModalGetStartedButton) {
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
    InformationalModalView(viewModel: InformationalModalViewModel())
        .environmentObject(Theme(previewTheme: .light))
}
