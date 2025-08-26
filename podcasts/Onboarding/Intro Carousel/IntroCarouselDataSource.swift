import SwiftUI

class IntroCarouselDataSource: StoriesDataSource {
    private let items: [CarouselItem]
    private let theme: Theme

    init(items: [CarouselItem], theme: Theme) {
        self.items = items
        self.theme = theme
    }

    var numberOfStories: Int { items.count }

    func story(for index: Int) -> any StoryView {
        IntroCarouselStory(item: items[index], theme: theme)
    }

    func storyView(for index: Int) -> AnyView {
        AnyView(IntroCarouselStory(item: items[index], theme: theme))
    }

    func shareableStory(for index: Int) -> (any ShareableStory)? {
        nil
    }

    func isInteractiveView(for index: Int) -> Bool {
        false
    }

    func isReady() async -> Bool {
        true
    }

    func refresh() async -> Bool {
        true
    }

    func paywallView() -> AnyView {
        AnyView(EmptyView())
    }

    func overlaidShareView() -> AnyView? {
        nil
    }

    func footerShareView() -> AnyView? {
        nil
    }

    var indicatorColor: Color {
        theme.primaryText01
    }

    var indicatorStyle: StoryIndicatorStyle {
        StoryIndicatorStyle(
            height: 4,
            borderRadius: 0, // Square corners for intro
            backgroundColor: theme.primaryField03,
            foregroundColor: theme.primaryText01
        )
    }

    var primaryBackgroundColor: Color {
        theme.primaryUi01
    }

    func sharingSnapshotModifier(_ view: AnyView) -> AnyView {
        view
    }
}
