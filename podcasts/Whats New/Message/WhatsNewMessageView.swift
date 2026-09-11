import PocketCastsServer
import SwiftUI

/// A What's New message, drawn in the predefined layout its type asked for.
struct WhatsNewMessageView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: WhatsNewMessageViewModel

    var body: some View {
        content
            .background(theme.primaryUi01.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.content {
        case .pages(let pages):
            WhatsNewPagesView(pages: pages)
        case .research(let research):
            WhatsNewPollView(research: research, viewModel: viewModel)
        }
    }
}

/// A standard message's pages, side by side and swiped through horizontally.
private struct WhatsNewPagesView: View {
    @State private var currentPage = 0

    let pages: [WhatsNewMessageViewModel.Page]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages) { page in
                    WhatsNewMessagePageView(page: page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if pages.count > 1 {
                WhatsNewPageIndicator(numberOfPages: pages.count, currentPage: currentPage)
                    .padding(.vertical, 20)
            }
        }
    }
}

/// A single page: its image, what it's about, and the one thing it offers to do next.
///
/// The page scrolls when a long translation or a larger text size makes it taller than the space
/// it's given, rather than clipping it, and keeps its call to action pinned beneath the content.
private struct WhatsNewMessagePageView: View {
    @EnvironmentObject private var theme: Theme

    /// The gutter the design leaves either side of a page's content.
    private let horizontalPadding: CGFloat = 20

    let page: WhatsNewMessageViewModel.Page

    var body: some View {
        GeometryReader { proxy in
            let contentSize = CGSize(width: proxy.size.width - horizontalPadding * 2, height: proxy.size.height)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    WhatsNewImageView(image: page.image, contentSize: contentSize)
                        .padding(.top, 32)

                    Text(page.heading)
                        .font(size: 17, style: .headline, weight: .semibold)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 40)

                    Text(page.description)
                        .font(size: 15, style: .subheadline)
                        .foregroundStyle(theme.primaryText01)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { action }
        }
    }

    /// The page's call to action, pinned beneath the content that scrolls behind it.
    @ViewBuilder
    private var action: some View {
        if let action = page.action {
            WhatsNewActionView(action: action)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(theme.primaryUi01)
        }
    }
}

/// A call to action, which does whatever this build maps its event to.
private struct WhatsNewActionView: View {
    @EnvironmentObject private var theme: Theme

    let action: WhatsNewMessageViewModel.Action

    var body: some View {
        Button(action.label) {
            action.event.perform()
        }
        .buttonStyle(RoundedButtonStyle(theme: theme))
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
    /// The mock catalog's message that pages through two screenshots and on to a call to action.
    static var multiPageMock: WhatsNewMessage { mock(titled: "Introducing episode transcripts") }

    /// The mock catalog's single-page message, which shows no pagination controls.
    static var singlePageMock: WhatsNewMessage { mock(titled: "Sort your Up Next") }

    /// The mock catalog's message whose description is longer than a page, so it has to scroll.
    static var longPageMock: WhatsNewMessage { mock(titled: "Everything new this month") }

    /// The mock catalog's message whose action names an event no client implements.
    static var unknownActionMock: WhatsNewMessage { mock(titled: "Downloads stalling on cellular") }

    /// The mock catalog's research message, which is a poll rather than a set of pages.
    static var researchMock: WhatsNewMessage { mock(titled: "Help shape the player") }

    private static func mock(titled title: String) -> WhatsNewMessage {
        WhatsNewCatalog.mock.messages.first { $0.title == title }!
    }
}

#Preview("Multiple pages") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .multiPageMock))
}

#Preview("A single page") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .singlePageMock))
}

#Preview("A long page") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .longPageMock))
}

#Preview("An action this build doesn't implement") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .unknownActionMock))
}

#Preview("A research poll") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .researchMock))
}

struct WhatsNewMessageView_Previews: PreviewProvider {
    /// A page has to hold up against every theme's background, calls to action included.
    static var previews: some View {
        WhatsNewMessageView(viewModel: WhatsNewMessageViewModel(message: .singlePageMock))
            .previewWithAllThemes()
    }
}
