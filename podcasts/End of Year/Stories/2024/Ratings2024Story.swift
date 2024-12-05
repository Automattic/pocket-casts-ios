import SwiftUI

struct Ratings2024Story: ShareableStory {

    let ratingScale = 1...5
    let ratings: [UInt32: Int]

    let foregroundColor: Color = .black
    let backgroundColor: Color = Color(hex: "#EFECAD")
    private let ratingsBlogPostURL = URL(string: "https://blog.pocketcasts.com/2024/08/20/podcast-ratings/")!

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: 0.8, animation: Animation.spring(_:))
    @Environment(\.animated) var animated: Bool
    @Environment(\.pauseState) var pauseState

    let identifier: String = "ratings"

    @State var scale: Double = 1
    @State var openURL = false

    var body: some View {
        Group {
            if ratings.count == 0 {
                emptyView()
            } else {
                VStack(alignment: .leading) {
                    Spacer()
                    chartView()
                        .modifier(animationViewModel.animate($scale, to: 1))
                        .padding()
                        .padding(.vertical, 32)
                    Spacer()
                    footerView()
                }
            }
        }
        .padding(.top, 24)
        .onAppear {
            if animated {
                setInitialCoverOffsetForAnimation()
                animationViewModel.play()
            }
        }
        .foregroundStyle(foregroundColor)
        .background(
            backgroundColor
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
    }

    private func setInitialCoverOffsetForAnimation() {
        scale = 0
    }

    @ViewBuilder func emptyView() -> some View {
        let words = ["OOOOPSIES"]
        let separator = Image("playback-2024-star")
        VStack {
            Spacer()
            VStack(spacing: 16) {
                MarqueeTextView(words: words, separator: separator, direction: .leading)
                MarqueeTextView(words: words, separator: separator, direction: .trailing)
            }
            .frame(height: 350)
            Spacer()
            emptyFooterView()
        }
    }

    @ViewBuilder func emptyFooterView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.playback2024RatingsEmptyTitle)
                .font(.system(size: 31, weight: .bold))
            Text(L10n.playback2024RatingsEmptyDescription)
                .font(.system(size: 15, weight: .light))
            Button(L10n.learnAboutRatings) {
                pauseState.togglePause()
                openURL = true
                Analytics.track(.endOfYearLearnRatingsShown)
            }
            .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.clear, borderColor: .black))
            .allowsHitTesting(true)
        }
        .minimumScaleFactor(0.5)
        .sheet(isPresented: $openURL, onDismiss: {
            pauseState.togglePause()
            openURL = false
        }, content: {
            SFSafariView(url: ratingsBlogPostURL)
        })
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }

    @ViewBuilder func chartView() -> some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom) {
                let maxRating = ratings.values.max() ?? 0
                ForEach(ratingScale, id: \.self) { ratingGroup in
                    let count = ratings[UInt32(ratingGroup)] ?? 0
                    VStack {
                        Text("\(ratingGroup)")
                            .font(.system(size: 22, weight: .semibold))
                            .opacity(scale)
                            .offset(x: 0, y: 10 * (1 - scale))
                        DashedRectangle()
                            .frame(height: max(geometry.size.height * (CGFloat(count) / CGFloat(maxRating)), 5))
                            .scaleEffect(x: 1, y: scale, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func descriptionText() -> String {
        switch mostCommonRating {
        case 1...3:
            return L10n.playback2024RatingsDescription1To3
        case 4...5:
            return L10n.playback2024RatingsDescription4To5(mostCommonRating)
        default:
            return ""
        }

    }

    private var mostCommonRating: UInt32 {
        ratings.max(by: { $0.value < $1.value })?.key ?? 0
    }

    @ViewBuilder func footerView() -> some View {
        StoryFooter2024(title: L10n.playback2024RatingsTitle, description: descriptionText())
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        let totalRatings = ratings.values.reduce(0, +)
        return [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyYearRatingsShareText(totalRatings, "2024", mostCommonRating), year: .y2024)
        ]
    }

    func hideShareButton() -> Bool {
        ratings.count == 0
    }
}

struct DashedRectangle: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                ForEach(0..<Int(geometry.size.height / 5), id: \.self) { _ in
                    Rectangle()
                        .frame(height: 1)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}
