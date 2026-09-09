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
/// clipping them, and keeps its calls to action pinned beneath them.
private struct WhatsNewMessagePageView: View {
    /// The gutter the design leaves either side of a page's content.
    private let horizontalPadding: CGFloat = 20

    /// The name the page's own geometry goes by, so the content and the actions can be measured
    /// against each other.
    private let coordinateSpace = "WhatsNewMessagePage"

    @State private var contentBottom: CGFloat = 0
    @State private var actionsTop: CGFloat = .greatestFiniteMagnitude

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
                .background {
                    GeometryReader { content in
                        Color.clear.preference(key: ContentBottomKey.self, value: content.frame(in: .named(coordinateSpace)).maxY)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { actions }
            .coordinateSpace(name: coordinateSpace)
            .onPreferenceChange(ContentBottomKey.self) { contentBottom = $0 }
            .onPreferenceChange(ActionsTopKey.self) { actionsTop = $0 }
        }
    }

    /// The page's calls to action, which the content scrolls behind. They take on a bar of their own
    /// while it is back there, the way a navigation bar does.
    @ViewBuilder
    private var actions: some View {
        if !page.actions.isEmpty {
            VStack(spacing: 12) {
                ForEach(Array(page.actions.enumerated()), id: \.offset) { _, action in
                    WhatsNewActionView(action: action)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background {
                if isContentBehindActions {
                    Rectangle().fill(.bar)
                }
            }
            .overlay(alignment: .top) {
                if isContentBehindActions {
                    Divider()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isContentBehindActions)
            .background {
                GeometryReader { actions in
                    Color.clear.preference(key: ActionsTopKey.self, value: actions.frame(in: .named(coordinateSpace)).minY)
                }
            }
        }
    }

    /// Whether the content has scrolled in behind the actions, which is when they need an edge.
    private var isContentBehindActions: Bool {
        contentBottom > actionsTop + 1
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
        default:
            return 20
        }
    }
}

/// How far down the page the scrolling content reaches.
private struct ContentBottomKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Where the page's actions begin.
private struct ActionsTopKey: PreferenceKey {
    static let defaultValue = CGFloat.greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
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

    /// The mock catalog's message whose blocks are taller than a page, so it has to scroll.
    static var longPageMock: WhatsNewMessage { mock(titled: "Everything new this month") }

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

#Preview("A long page") {
    PCNavigationController(rootViewController: WhatsNewMessageViewController(message: .longPageMock))
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
