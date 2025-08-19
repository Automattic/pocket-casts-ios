import SwiftUI

struct IntroCarouselView: View {
    @EnvironmentObject var theme: Theme

    private let carouselItems = [
        CarouselItem(
            contentView: {
                VStack(spacing: 100) {
                    Image("small-horizontal-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)

                    Image("intro-carousel-podcasts")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            },
            title: "\"The best podcast app out there. By far\"",
            description: "Pocket Casts user"
        ),
        CarouselItem(
            contentView: {
                Image("intro-carousel-effects")
                    .mask(
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: .clear, location: 0.0),
                                Gradient.Stop(color: .black, location: 0.1),
                                Gradient.Stop(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            },
            title: "\"The amount of customization is insane\"",
            description: "Pocket Casts user"
        ),
        CarouselItem(
            contentView: {
                Image("intro-carousel-folders")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            },
            title: "\"Organizing my podcasts by folders is genius\"",
            description: "Pocket Casts user"
        )
    ]

    private var configuration: StoriesConfiguration {
        let configuration = StoriesConfiguration()
        configuration.shouldShowDismissButton = false
        configuration.indicatorHeight = 4
        return configuration
    }

    var body: some View {
        VStack(spacing: 36) {
            StoriesView(
                dataSource: IntroCarouselDataSource(items: carouselItems, theme: theme),
                configuration: configuration
            )

            VStack(spacing: 16) {
                Button(L10n.eacInformationalViewModalGetStartedButton) {
                    // Will implement in follow up PR
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))

                Button(L10n.accountLogin) {
                    // Will implement in follow up PR
                }
                .foregroundColor(theme.primaryText01)
                .font(.system(size: 18, weight: .semibold))
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
        .modifier(DefaultThemeSettings())
    }
}

struct CarouselItem {
    let contentView: () -> any View
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

// MARK: - Story View

struct IntroCarouselStory: StoryView {
    let item: CarouselItem
    let theme: Theme

    @State private var iconOpacity: Double = 0
    @State private var iconOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var descriptionOpacity: Double = 0
    @State private var descriptionOffset: CGFloat = 30

    var duration: TimeInterval { 3.0 }
    var identifier: String { item.title }
    var plusOnly: Bool { false }

    var body: some View {
        VStack {
            Spacer()

            AnyView(item.contentView())
                .opacity(iconOpacity)
                .offset(y: iconOffset)

            Spacer()

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Text(item.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ThemeColor.primaryText02(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(descriptionOpacity)
                    .offset(y: descriptionOffset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryUi01)
        .onAppear {
            startAnimations()
        }
        .id(identifier)
    }

    private func startAnimations() {
        // Reset to initial state
        iconOpacity = 0
        iconOffset = 30
        titleOpacity = 0
        titleOffset = 30
        descriptionOpacity = 0
        descriptionOffset = 30

        // Start sequential animations
        withAnimation(.easeOut(duration: 0.6)) {
            iconOpacity = 1
            iconOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.6)) {
                titleOpacity = 1
                titleOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                descriptionOpacity = 1
                descriptionOffset = 0
            }
        }
    }

    func onAppear() {

    }

    func onPause() {

    }

    func onResume() {

    }
}
