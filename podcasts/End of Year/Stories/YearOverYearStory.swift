import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct YearOverYearStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "year_over_year"

    let yearOverYearListeningTime: YearOverYearListeningTime

    let subscriptionTier: SubscriptionTier = SubscriptionHelper.subscriptionTier

    var title: String {
        let listeningPercentage = yearOverYearListeningTime.percentage
        switch listeningPercentage {
        case _ where listeningPercentage == .infinity:
            return L10n.eoyYearOverYearTitleSkyrocketed
        case _ where listeningPercentage > 10:
            return L10n.eoyYearOverYearTitleWentUp("\(listeningPercentage.clean)%")
        case _ where listeningPercentage < 0:
            return L10n.eoyYearOverYearTitleWentDown
        default:
            return L10n.eoyYearOverYearTitleFlat
        }
    }

    var subtitle: String {
        let listeningPercentage = yearOverYearListeningTime.percentage
        switch listeningPercentage {
        case _ where listeningPercentage > 10:
            return L10n.eoyYearOverYearSubtitleWentUp
        case _ where listeningPercentage < 0:
            return L10n.eoyYearOverYearSubtitleWentDown
        default:
            return L10n.eoyYearOverYearSubtitleFlat
        }
    }

    var leftBarPercentageSize: Double {
        let percentage = yearOverYearListeningTime.percentage
        if percentage == .infinity {
            return 0.2
        } else if percentage > 0 {
            return max(yearOverYearListeningTime.totalPlayedTimeLastYear / yearOverYearListeningTime.totalPlayedTimeThisYear, minimumBarPercentage)
        }

        return 1
    }

    var rightBarPercentageSize: Double {
        let percentage = yearOverYearListeningTime.percentage
        if percentage < 0 {
            return max(yearOverYearListeningTime.totalPlayedTimeThisYear / yearOverYearListeningTime.totalPlayedTimeLastYear, minimumBarPercentage)
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
                        HStack(alignment: .bottom, spacing: 0) {
                            bar(
                                title: "2022",
                                subtitle: yearOverYearListeningTime.totalPlayedTimeLastYear.storyTimeDescription,
                                geometry: geometry,
                                barStyle: .grey
                            )
                            .frame(height: leftBarPercentageSize * proxy.size.height)

                            bar(
                                title: "2023",
                                subtitle: yearOverYearListeningTime.totalPlayedTimeThisYear.storyTimeDescription,
                                geometry: geometry,
                                barStyle: .rainbow
                            )
                            .frame(height: rightBarPercentageSize * proxy.size.height)

                        }
                    }

                }
            }
            .background(.black)
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
                .font(.custom("DM Sans", size: geometry.size.height * 0.09).weight(.medium))
                .foregroundColor(.white)

                Text(subtitle)
                .font(.custom("DM Sans", size: geometry.size.height * 0.018).weight(.semibold))
                .padding(.top, -geometry.size.height * 0.08)
                .foregroundColor(.white)
            }
            .opacity(barStyle == .grey ? 0.5 : 1)
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
        YearOverYearStory(yearOverYearListeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 200, totalPlayedTimeLastYear: 400))
            .previewDisplayName("Went down")

        YearOverYearStory(yearOverYearListeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 200, totalPlayedTimeLastYear: 130))
            .previewDisplayName("Went up")

        YearOverYearStory(yearOverYearListeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 140, totalPlayedTimeLastYear: 130))
            .previewDisplayName("Stayed same")

        YearOverYearStory(yearOverYearListeningTime: YearOverYearListeningTime(totalPlayedTimeThisYear: 140, totalPlayedTimeLastYear: 0))
            .previewDisplayName("No listening time for past year")
    }
}
