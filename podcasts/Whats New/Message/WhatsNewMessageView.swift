import PocketCastsServer
import SwiftUI

/// A What's New message: its pages side by side, swiped through horizontally.
struct WhatsNewMessageView: View {
    @EnvironmentObject private var theme: Theme
    @State private var currentPage = 0

    let viewModel: WhatsNewMessageViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(viewModel.pages) { page in
                    WhatsNewMessagePageView(page: page, isVisible: page.id == currentPage)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if viewModel.pages.count > 1 {
                WhatsNewPageIndicator(numberOfPages: viewModel.pages.count, currentPage: currentPage)
                    .padding(.vertical, 20)
            }
        }
        .background(theme.primaryUi01.ignoresSafeArea())
    }
}

/// A single page, which scrolls when its blocks are taller than the space they're given rather than
/// clipping them.
private struct WhatsNewMessagePageView: View {
    /// The gutter the design leaves either side of a page's content.
    private let horizontalPadding: CGFloat = 20

    let page: WhatsNewMessageViewModel.Page
    let isVisible: Bool

    var body: some View {
        GeometryReader { proxy in
            let contentSize = CGSize(width: proxy.size.width - horizontalPadding * 2, height: proxy.size.height)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(page.blocks.enumerated()), id: \.offset) { index, block in
                        WhatsNewBlockView(block: block, contentSize: contentSize, isVisible: isVisible)
                            .padding(.top, topPadding(forBlockAt: index))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 24)
            }
        }
    }

    /// The space the design leaves above a block, which depends on what it follows.
    private func topPadding(forBlockAt index: Int) -> CGFloat {
        guard index > 0 else { return 32 }

        switch (page.blocks[index - 1], page.blocks[index]) {
        case (_, .image), (_, .video):
            return 32
        case (.image, _), (.video, _):
            return 40
        case (.heading, .paragraph):
            return 16
        case (_, .action):
            return 28
        default:
            return 20
        }
    }
}

/// The dots under a message with more than one page.
private struct WhatsNewPageIndicator: View {
    @EnvironmentObject private var theme: Theme

    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? theme.primaryUi05Selected : theme.primaryUi05)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.pageControlPageProgressFormat("\(currentPage + 1)", "\(numberOfPages)"))
    }
}

// MARK: - Previews

private extension WhatsNewMessage {
    /// The mock catalog's message that pages through a screenshot and on to a call to action.
    static var multiPageMock: WhatsNewMessage { mock(titled: "Introducing episode transcripts") }

    /// The mock catalog's single-page message, which shows no pagination controls.
    static var singlePageMock: WhatsNewMessage { mock(titled: "Sort your Up Next") }

    /// The mock catalog's message built around a video demo.
    static var videoMock: WhatsNewMessage { mock(titled: "Downloads stalling on cellular") }

    /// The mock catalog's message whose call to action is the secondary style.
    static var secondaryActionMock: WhatsNewMessage { mock(titled: "Ads to support Pocket Casts") }

    private static func mock(titled title: String) -> WhatsNewMessage {
        WhatsNewCatalog.mock.messages.first { $0.summary.title == title }!
    }
}

#Preview("Multiple pages") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .multiPageMock))
}

#Preview("A single page") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .singlePageMock))
}

#Preview("A video demo") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .videoMock))
}

struct WhatsNewMessageView_Previews: PreviewProvider {
    /// The secondary call to action is the one that has to hold up against every theme's background.
    static var previews: some View {
        WhatsNewMessageView(viewModel: WhatsNewMessageViewModel(message: .secondaryActionMock))
            .previewWithAllThemes()
    }
}
