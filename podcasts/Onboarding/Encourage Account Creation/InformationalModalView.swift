import SwiftUI

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
        ScrollView {
            title
            description
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
                    showPagination: true
                )
            }
            .frame(height: cardHeight + 24.0)
            buttons
                .padding(.top, isiPad ? 12.0 : 39.0)
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

    private var title: some View {
        Text("We noticed you’re not logged in")
            .font(size: 22.0, style: .body, weight: .bold)
            .foregroundStyle(theme.primaryText01)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24.0)
            .padding(.top, isiPad ? 20.0 : 34.0)
            .padding(.bottom, 8.0)
    }

    private var description: some View {
        Text("Create an account or log in to enjoy\nPocket Casts to the fullest.")
            .font(size: 15.0, style: .body, weight: .medium)
            .foregroundStyle(theme.primaryText02)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24.0)
            .padding(.bottom, isiPad ? 20.0 : 24.0)
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            Button("Get Started") {
                viewModel.getStarted()
            }
            .buttonStyle(RoundedButtonStyle(theme: theme))

            Button("Login") {
                viewModel.getStarted()
            }
            .buttonStyle(SimpleTextButtonStyle(theme: theme))
        }
    }
}

#Preview {
    InformationalModalView(viewModel: InformationalModalViewModel())
        .environmentObject(Theme(previewTheme: .light))
}
