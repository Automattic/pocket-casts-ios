import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct ListeningTimeStory: ShareableStory {
    let duration: TimeInterval = EndOfYear.defaultDuration

    let identifier: String = "listening_time"

    let listeningTime: Double

    let podcasts: [Podcast]

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    StoryLabel(L10n.eoyStoryListenedToTitle, for: .title, geometry: geometry)
                        .fixedSize(horizontal: false, vertical: true)
                    StoryLabel(L10n.eoyStoryListenedToSubtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                // We treat numbers below 21 differently, as there's much more space available
                let maxHeight = Int(listeningTime.firstNumber) ?? 0 <= 21 ? 0.5 : 0.35
                let subtitleTopPadding = (Int(listeningTime.firstNumber) ?? 0 <= 21 ? 0.35 : 0.25)
                Text(listeningTime.firstNumber)
                    .font(.custom("DM Sans", size: geometry.size.height * 0.4))
                    .fontWeight(.regular)
                    .frame(width: geometry.size.width - 70)
                    .frame(maxHeight: geometry.size.height * maxHeight)
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding([.leading, .trailing], 35)
                    .overlay {
                        StoryLabel(listeningTime.subtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                            .padding(.top, geometry.size.height * subtitleTopPadding)
                    }

                Spacer()

                CircleDays(proxy: geometry, listeningTime: listeningTime)

                Spacer()

                Rectangle()
                    .frame(height: geometry.size.height * 0.1)
                    .opacity(0)
            }
            .background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient(geometry: geometry)
                    .offset(x: -geometry.size.width * 0.8, y: geometry.size.height * 0.25)
                }
            )
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryListenedToShareText(listeningTime.storyTimeDescriptionForSharing))
        ]
    }
}

/// Given a GeometryProxy and a Double listening time it
/// returns a view filled with circles representing days of listening.
///
/// The minimum amount of circles is 7.
///
/// The algorithm takes a `maxArea` and calculates how many balls it
/// can fill there. However the returned `View` might be bigger or smaller,
/// the area just give it some constraints to calculate values.
struct CircleDays: View {
    let proxy: GeometryProxy
    let listeningTime: Double

    var body: some View {
        let maxArea = CGSize(width: proxy.size.width, height: proxy.size.height * 0.3)
        let number = Double(listeningTime / 86400).rounded(.up)
        let eachBallSquareArea = Double(maxArea.width * maxArea.height) / number
        let numberOfBallsPerLine = max(7, (maxArea.width / eachBallSquareArea.squareRoot()).rounded(.up))
        let numberOfLines = min((number / numberOfBallsPerLine).rounded(.up), max(1, (maxArea.height / eachBallSquareArea.squareRoot()).rounded(.up)))
        let ballCalculatedWidth = maxArea.width / numberOfBallsPerLine
        let ballCalculatedHeight = maxArea.height / numberOfLines
        let ballPadding = min(ballCalculatedWidth, ballCalculatedHeight) * 0.05
        let ballFinalWidth = min(ballCalculatedWidth, ballCalculatedHeight) - 4 * ballPadding

        // The width of the days displayed as balls that the user didn't listened to podcasts
        let missingDaysWidth = ((((numberOfLines * numberOfBallsPerLine) * 86400) - listeningTime) / 86400) * (ballFinalWidth + (2 * ballPadding))

        // The content is repeated on the background so the gradient
        // can have the exact same size as the circles.
        VStack(spacing: 0) {
            circles(numberOfLines: numberOfLines, numberOfBallsPerLine: numberOfBallsPerLine, ballWidth: ballFinalWidth, ballPadding: ballPadding)
            .opacity(0)
        }
        .background(
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
                        Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
                        Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.76),
                        Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0, y: 0),
                    endPoint: UnitPoint(x: 1.22, y: 1.25)
                )

                // Fill the non-listened days
                Rectangle()
                    .foregroundStyle(Color(hex: "8F97A4"))
                    .frame(width: missingDaysWidth, height: ballFinalWidth + 2 * ballPadding)
            }
            .mask (
                VStack(spacing: 0) {
                    circles(numberOfLines: numberOfLines, numberOfBallsPerLine: numberOfBallsPerLine, ballWidth: ballFinalWidth, ballPadding: ballPadding)
                }
            )

        )
    }

    func circles(numberOfLines: Double, numberOfBallsPerLine: Double, ballWidth: Double, ballPadding: Double) -> some View {
        ForEach(0..<Int(numberOfLines), id: \.self) { _ in
            HStack(spacing: 0) {
                ForEach(0..<Int(numberOfBallsPerLine), id: \.self) { _ in
                    Circle()
                        .foregroundStyle(.white)
                        .frame(width: ballWidth, height: ballWidth)
                        .padding(.all, ballPadding)
                }
            }
        }
    }
}

private extension Double {
    var firstNumber: String {
        storyTimeDescription.components(separatedBy: "\u{00a0}").first ?? ""
    }

    var subtitle: String {
        storyTimeDescription.components(separatedBy: "\u{00a0}").dropFirst().joined(separator: "\u{00a0}")
    }
}

struct ListeningTimeStory_Previews: PreviewProvider {
    static var previews: some View {
        ListeningTimeStory(listeningTime: 109000, podcasts: [Podcast.previewPodcast(), Podcast.previewPodcast(), Podcast.previewPodcast()])
    }
}
