import SwiftUI
import PocketCastsServer

struct StoriesView: View {
    @ObservedObject private var model: StoriesModel
    @Environment(\.accessibilityShowButtonShapes) var showButtonShapes: Bool

    init(dataSource: StoriesDataSource, configuration: StoriesConfiguration = StoriesConfiguration()) {
        model = StoriesModel(dataSource: dataSource, configuration: configuration)
    }

    @ViewBuilder
    var body: some View {
        if model.isReady {
            stories
            .onAppear {
                model.start()
            }
        } else if model.failed {
            failed
        } else {
            loading
        }
    }

    var stories: some View {
        ZStack {
            Spacer()

            storiesToPreload

            ZStack {
                // Manually set the zIndex order to ensure we can change the order when needed
                model.story(index: model.currentStory).zIndex(3).ignoresSafeArea(edges: .bottom)

                // By default the story switcher will appear above the story and override all
                // interaction, but if the story contains interactive elements then move the
                // switcher to appear behind the view to allow the story override the switcher, or
                // allow the story to pass switcher events thru by controlling the allowsHitTesting
                storySwitcher.zIndex(model.isInteractiveView(index: model.currentStory) ? 2 : 5)
            }

            header

            // Hide the share button if needed
            if model.storyIsShareable(index: model.currentStory) {
                VStack {
                    Spacer()
                    shareButton
                }
            }
        }
        .background(Color.black)
    }

    // View shown while data source is preparing
    var loading: some View {
        ZStack {
            Spacer()

            VStack(spacing: 15) {
                let progress = SyncYearListeningProgress.shared.progress
                CircularProgressView(value: progress, stroke: Color.white, strokeWidth: 6)
                    .frame(width: 40, height: 40)
                Text(L10n.loading)
                    .foregroundColor(.white)
                    .font(style: .body)
            }

            storySwitcher
            header
        }
    }

    var failed: some View {
        ZStack {
            Spacer()

            Text(L10n.eoyStoriesFailed)
                .foregroundColor(.white)

            storySwitcher
            header
        }
        .onAppear {
            Analytics.track(.endOfYearStoriesFailedToLoad)
        }
    }

    // Header containing the close button and the rectangles
    var header: some View {
        ZStack {
            VStack {
                HStack(spacing: 2) {
                    ForEach(0 ..< model.numberOfStories, id: \.self) { x in
                        StoryIndicator(index: x)
                    }
                }
                .frame(height: Constants.storyIndicatorHeight)
                .padding(.top, 4)
                Spacer()
            }
            .padding(.leading, Constants.storyIndicatorVerticalPadding)
            .padding(.trailing, Constants.storyIndicatorVerticalPadding)

            closeButton
        }
        .padding(.top, Constants.headerTopPadding)
    }

    var closeButton: some View {
            VStack {
                HStack {
                    Spacer()
                    Button("") {
                        Analytics.track(.endOfYearStoriesDismissed, properties: ["source": "close_button"])
                        model.stopAndDismiss()
                    }.buttonStyle(CloseButtonStyle(showButtonShapes: showButtonShapes))
                    // Inset the button a bit if we're showing the button shapes
                    .padding(.trailing, showButtonShapes ? Constants.storyIndicatorVerticalPadding : 5)
                    .padding(.top, 5)
                    .accessibilityLabel(L10n.accessibilityDismiss)
                }
                .padding(.top, Constants.closeButtonTopPadding)
                Spacer()
            }
        }

    // Invisible component to go to the next/prev story
    var storySwitcher: some View {
        HStack(alignment: .center, spacing: Constants.storySwitcherSpacing) {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    model.previous()
                }
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    model.next()
                }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in
                    model.pause()
                }
                .onEnded { value in
                    let velocity = CGSize(
                        width: value.predictedEndLocation.x - value.location.x,
                        height: value.predictedEndLocation.y - value.location.y
                    )

                    // If a quick swipe down is performed, dismiss the view
                    if velocity.height > 200 {
                        Analytics.track(.endOfYearStoriesDismissed, properties: ["source": "swipe_down"])
                        model.stopAndDismiss()
                    } else {
                        model.start()
                    }
                }
        )
    }

    var shareButton: some View {
        Button(L10n.eoyShare) {
            model.share()
        }
        .buttonStyle(ShareButtonStyle())
        .padding([.leading, .trailing], Constants.shareButtonHorizontalPadding)
    }

    var storiesToPreload: some View {
        ZStack {
            if model.numberOfStoriesToPreload > 0 {
                ForEach(0...model.numberOfStoriesToPreload, id: \.self) { index in
                    model.preload(index: model.currentStory + index + 1)
                }
            }
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
}

// MARK: - Constants

private extension StoriesView {
    struct Constants {
        static let storyIndicatorHeight: CGFloat = 2
        static let storyIndicatorVerticalPadding: CGFloat = 13
        static let headerTopPadding: CGFloat = 5

        static let closeButtonPadding: CGFloat = 13
        static let closeButtonTopPadding: CGFloat = 5

        static let storySwitcherSpacing: CGFloat = 0
        static let shareButtonHorizontalPadding: CGFloat = 20

        static let spaceBetweenShareAndStory: CGFloat = 15

        static let storyCornerRadius: CGFloat = 15
    }
}

// MARK: - Custom Buttons

private struct ShareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            Image("share")
            configuration.label
            Spacer()
        }
        .font(.custom("DM Sans", size: 14, relativeTo: .body).bold())
        .foregroundColor(Constants.shareButtonColor)

        .padding([.top, .bottom], Constants.shareButtonVerticalPadding)

        .applyButtonEffect(isPressed: configuration.isPressed)
        .contentShape(Rectangle())
    }

    private struct Constants {
        static let shareButtonColor = Color.white
        static let shareButtonVerticalPadding: CGFloat = 13
        static let shareButtonCornerRadius: CGFloat = 12
        static let shareButtonBorderSize: CGFloat = 2
    }
}

private struct CloseButtonStyle: ButtonStyle {
    let showButtonShapes: Bool

    func makeBody(configuration: Configuration) -> some View {
        Image("eoy-close")
            .font(style: .body, maxSizeCategory: .extraExtraExtraLarge)
            .foregroundColor(.white)
            .padding(Constants.closeButtonPadding)
            .background(showButtonShapes ? Color.white.opacity(0.2) : nil)
            .cornerRadius(Constants.closeButtonRadius)
            .contentShape(Rectangle())
            .applyButtonEffect(isPressed: configuration.isPressed)
    }

    private enum Constants {
        static let closeButtonPadding: CGFloat = 13
        static let closeButtonRadius: CGFloat = 5
    }
}

struct StoryViewContainer<Content: View>: View {
    private var content: () -> Content

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        ZStack {
            content()
            StoryLogoView().zIndex(4)
        }
    }
}

// MARK: - Preview Provider

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(dataSource: EndOfYearStoriesDataSource())
    }
}
