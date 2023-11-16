import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct YearOverYearStory: ShareableStory {
    @Environment(\.animated) var animated: Bool

    let duration: TimeInterval = EndOfYear.defaultDuration

    let identifier: String = "year_over_year"

    let plusOnly = true

    var data: YearOverYearListeningTime

    let subscriptionTier: SubscriptionTier = SubscriptionHelper.subscriptionTier

    @ObservedObject private var animationViewModel = PlayPauseAnimationViewModel(duration: 0.8, animation: Animation.easeInOut(duration:))

    var title: String {
        switch data.percentage {
        case .infinity:
            L10n.eoyYearOverYearTitleSkyrocketed
        case 10...:
            L10n.eoyYearOverYearTitleWentUp("\(data.percentage.clean)%")
        case ...0:
            L10n.eoyYearOverYearTitleWentDown
        default:
            L10n.eoyYearOverYearTitleFlat
        }
    }

    var subtitle: String {
        switch data.percentage {
        case 10...:
            L10n.eoyYearOverYearSubtitleWentUp
        case ...0:
            L10n.eoyYearOverYearSubtitleWentDown
        default:
            L10n.eoyYearOverYearSubtitleFlat
        }
    }

    @State var leftBarPercentageSize: Double = 0
    @State var rightBarPercentageSize: Double = 0

    @State var leftBarOpacity: Double = 0
    @State var rightBarOpacity: Double = 0

    var finalLeftBarPercentageSize: Double {
        let percentage = data.percentage
        if percentage == .infinity {
            return minimumBarPercentage
        } else if percentage > 0 {
            return max(data.totalPlayedTimeLastYear / data.totalPlayedTimeThisYear, minimumBarPercentage)
        }

        return 1
    }

    var finalRightBarPercentageSize: Double {
        let percentage = data.percentage
        if percentage < 0 {
            return max(data.totalPlayedTimeThisYear / data.totalPlayedTimeLastYear, minimumBarPercentage)
        }

        return 1
    }

    private let minimumBarPercentage: Double = 0.4

    var body: some View {
        GeometryReader { geometry in
            PodcastCoverContainer(geometry: geometry) {
                StoryLabelContainer(geometry: geometry) {
                    SubscriptionBadge(tier: subscriptionTier, displayMode: .gradient, foregroundColor: .black)
                    StoryLabel(title, for: .title, geometry: geometry)
                    StoryLabel(subtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }
                .padding(.bottom, geometry.size.height * 0.06)

                Spacer()

                ZStack(alignment: .bottom) {

                    GeometryReader { proxy in
                        VStack(spacing: 0) {
                            Spacer()

                            HStack(alignment: .bottom, spacing: 0) {
                                bar(
                                    title: "2022",
                                    subtitle: data.totalPlayedTimeLastYear.storyTimeDescription,
                                    geometry: geometry,
                                    barStyle: .grey
                                )
                                .frame(height: leftBarPercentageSize * proxy.size.height)
                                .modifier(animationViewModel.animate($leftBarPercentageSize, to: finalLeftBarPercentageSize))

                                bar(
                                    title: "2023",
                                    subtitle: data.totalPlayedTimeThisYear.storyTimeDescription,
                                    geometry: geometry,
                                    barStyle: .rainbow
                                )
                                .frame(height: rightBarPercentageSize * proxy.size.height)
                                .modifier(animationViewModel.animate($rightBarPercentageSize, to: finalRightBarPercentageSize))

                            }
                        }
                    }

                }
            }
            .background(.black)
            .onAppear {
                if animated {
                    animationViewModel.play()
                } else {
                    leftBarPercentageSize = finalLeftBarPercentageSize
                    rightBarPercentageSize = finalRightBarPercentageSize
                    leftBarOpacity = 0.5
                    rightBarOpacity = 1
                }
            }
        }
    }

    private func bar(title: String, subtitle: String, geometry: GeometryProxy, barStyle: BarStyle) -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .foregroundColor(.clear)
                .background(
                    VStack {
                        Spacer()
                        Rectangle()
                          .foregroundColor(.clear)
                          .frame(height: geometry.size.height * 0.35)
                          .background(
                            LinearGradient(
                              stops: [
                                Gradient.Stop(color: .black.opacity(0), location: 0.00),
                                Gradient.Stop(color: .black, location: 1.00),
                              ],
                              startPoint: UnitPoint(x: 0.5, y: 0.05),
                              endPoint: UnitPoint(x: 0.5, y: 0.89)
                            )
                          )
                    }
                )
                .background(
                    gradient(for: barStyle)
                )

            VStack(alignment: .leading) {
                Text(title)
                .font(.custom("DM Sans", size: geometry.size.height * 0.08).weight(.medium))
                .foregroundColor(.white)

                Text(subtitle)
                .font(.custom("DM Sans", size: geometry.size.height * 0.015).weight(.semibold))
                .padding(.top, -geometry.size.height * 0.075)
                .foregroundColor(.white)
            }
            .opacity(barStyle == .grey ? leftBarOpacity : rightBarOpacity)
            .modifier(animationViewModel.animate(barStyle == .grey ? $leftBarOpacity : $rightBarOpacity, to: barStyle == .grey ? 0.5 : 1, after: 0.4))
        }
    }

    @ViewBuilder
    private func gradient(for barStyle: BarStyle) -> some View {
        switch barStyle {
        case .grey:
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.31, green: 0.31, blue: 0.31), location: 0.00),
                    Gradient.Stop(color: .black.opacity(0), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        case .rainbow:
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.24),
                    Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.50),
                    Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.74),
                    Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.8, y: 1.27),
                endPoint: UnitPoint(x: 0.76, y: -0.44)
            )
        }
    }

    private enum BarStyle {
        case grey
        case rainbow
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: identifier)
    }

    func onPause() {
        animationViewModel.pause()
    }

    func onResume() {
        animationViewModel.play()
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyYearOverShareText)
        ]
    }
}

private extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

struct YearOverYearStory_Previews: PreviewProvider {
    static var previews: some View {
        YearOverYearStory(data: YearOverYearListeningTime(totalPlayedTimeThisYear: 200, totalPlayedTimeLastYear: 400))
            .previewDisplayName("Went down")

        YearOverYearStory(data: YearOverYearListeningTime(totalPlayedTimeThisYear: 200, totalPlayedTimeLastYear: 130))
            .previewDisplayName("Went up")

        YearOverYearStory(data: YearOverYearListeningTime(totalPlayedTimeThisYear: 140, totalPlayedTimeLastYear: 130))
            .previewDisplayName("Stayed same")

        YearOverYearStory(data: YearOverYearListeningTime(totalPlayedTimeThisYear: 140, totalPlayedTimeLastYear: 0))
            .previewDisplayName("No listening time for past year")
    }
}
