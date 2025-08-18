import SwiftUI

struct IntroCarouselView: View {
    @EnvironmentObject var theme: Theme

    private let carouselItems = [
        CarouselItem(title: "The best podcast app out there. By far", description: "Pocket Casts user"),
        CarouselItem(title: "The amount of customization is insane", description: "Pocket Casts user"),
        CarouselItem(title: "Organizing my podcasts by folders is genius", description: "Pocket Casts user")
    ]

    private var configuration: StoriesConfiguration {
        let configuration = StoriesConfiguration()
        configuration.shouldShowDismissButton = false
        return configuration
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            StoriesView(
                dataSource: IntroCarouselDataSource(items: carouselItems, theme: theme),
                configuration: configuration
            )
//                configuration: StoriesConfiguration(
//                    progressBarTintColor: theme.primaryInteractive01,
//                    progressBarBackgroundColor: theme.primaryInteractive03,
//                    dismissButtonTintColor: theme.primaryText01
//                )
//            .frame(height: 400)

            Spacer()

            VStack(spacing: 16) {
                Button(L10n.eacInformationalViewModalGetStartedButton) {
                    // Handle get started action
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))

                Button(L10n.accountLogin) {
                    // Handle login action
                }
                .foregroundColor(theme.primaryText01)
                .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 10)
        }
        .modifier(DefaultThemeSettings())
    }
}

struct CarouselItem {
    let title: String
    let description: String
}

// MARK: - Data Source

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

    var primaryBackgroundColor: Color {
        theme.primaryUi01
    }

    func sharingSnapshotModifier(_ view: AnyView) -> AnyView {
        view
    }
}

// MARK: - Story View

struct IntroCarouselStory: StoryView {
    let item: CarouselItem
    let theme: Theme

    var duration: TimeInterval { 3.0 }
    var identifier: String { item.title }
    var plusOnly: Bool { false }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)

                Text(item.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ThemeColor.primaryText02(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryUi01)
    }

    func onAppear() {

    }

    func onPause() {

    }

    func onResume() {

    }
}
