import SwiftUI

struct StoriesView: View {
    @ObservedObject private var model: StoriesModel

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
        VStack {
            ZStack {
                Spacer()

                storiesToPreload

                ZStack {
                    model.story(index: model.currentStory)
                }
                .cornerRadius(Constants.storyCornerRadius)

                storySwitcher

                ZStack {
                    model.interactive(index: model.currentStory)
                }
                .cornerRadius(Constants.storyCornerRadius)

                header
            }

            ZStack {}
                .frame(height: Constants.spaceBetweenShareAndStory)

            shareButton
        }
        .background(Color.black)
    }

    // View shown while data source is preparing
    var loading: some View {
        ZStack {
            Spacer()

            ProgressView()
                .colorInvert()
                .brightness(1)
                .padding()
                .background(Color.black)

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
                HStack {
                    ForEach(0 ..< model.numberOfStories, id: \.self) { x in
                        StoryIndicator(index: x)
                    }
                }
                .frame(height: Constants.storyIndicatorHeight)
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
                    Button(action: {
                        Analytics.track(.endOfYearStoriesDismissed, properties: ["source": "close_button"])
                        NavigationManager.sharedManager.dismissPresentedViewController()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(Constants.closeButtonPadding)
                    }
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
                        NavigationManager.sharedManager.dismissPresentedViewController()
                    } else {
                        model.start()
                    }
                }
        )
    }

    var shareButton: some View {
        Button(action: {
            model.share()
        }) {
            HStack {
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                Text("Share")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .padding(.top, Constants.shareButtonVerticalPadding)
        .padding(.bottom, Constants.shareButtonVerticalPadding)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.shareButtonCornerRadius)
                .stroke(.white, style: StrokeStyle(lineWidth: Constants.shareButtonBorderSize))
        )
        .padding(.leading, Constants.shareButtonHorizontalPadding)
        .padding(.trailing, Constants.shareButtonHorizontalPadding)
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

        static let shareButtonVerticalPadding: CGFloat = 10
        static let shareButtonHorizontalPadding: CGFloat = 5
        static let shareButtonCornerRadius: CGFloat = 10
        static let shareButtonBorderSize: CGFloat = 1

        static let spaceBetweenShareAndStory: CGFloat = 15

        static let storyCornerRadius: CGFloat = 15
    }
}

// MARK: - Preview Provider

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(dataSource: EndOfYearStoriesDataSource())
    }
}
