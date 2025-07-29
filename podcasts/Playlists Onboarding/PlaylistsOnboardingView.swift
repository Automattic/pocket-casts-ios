import SwiftUI

struct PlaylistsOnboardingView: View {
    @EnvironmentObject var theme: Theme
    @State private var currentIndex: Int? = 0

    let onClose: () -> Void

    private let cards = PlaylistsOnboardingCard.allCases

    var body: some View {
        GeometryReader { size in
            VStack {
                ScrollView(.vertical) {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 0) {
                                ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                                    PlaylistsOnboardingCardView(card: card)
                                        .frame(width: size.size.width)
                                        .id(i)
                                }
                            }
                            .withScrollTargetLayout()
                        }
                        .scrollIndicators(.hidden)
                        .withPaging(
                            minPage: 0,
                            maxPage: cards.count,
                            currentPage: $currentIndex,
                            scrollProxy: proxy
                        )
                    }
                }
                .scrollIndicators(.hidden)
                PageIndicatorView(numberOfItems: cards.count, currentPage: currentIndex ?? 0)
                    .foregroundColor(theme.primaryText01)
                    .padding(.bottom, 26.0)
                Button(action: closeView) {
                    Text(L10n.gotIt)
                }
                .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
                .frame(minHeight: 56)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(theme.primaryUi01)
            .onAppear {
                Settings.shouldShowPlaylistsOnboarding = false
            }
        }
    }

    func closeView() {
        onClose()
    }
}

#Preview {
    PlaylistsOnboardingView(onClose: {})
        .environmentObject(Theme.sharedTheme)
}
