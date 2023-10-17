import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct YearOverYearStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "year_over_year"

    let yearOverYearListeningTime: YearOverYearListeningTime

    let subscriptionTier: SubscriptionTier = .plus

    var title: String {
        let listeningPercentage = yearOverYearListeningTime.percentage
        switch listeningPercentage {
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
            return max(yearOverYearListeningTime.totalPlayedTimeLastYear / yearOverYearListeningTime.totalPlayedTimeThisYear, 0.4)
        }

        return 1
    }

    var rightBarPercentageSize: Double {
        let percentage = yearOverYearListeningTime.percentage
        if percentage < 0 {
            return max(yearOverYearListeningTime.totalPlayedTimeThisYear / yearOverYearListeningTime.totalPlayedTimeLastYear, 0.4)
        }

        return 1
    }

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
                                        LinearGradient(
                                        stops: [
                                        Gradient.Stop(color: Color(red: 0.31, green: 0.31, blue: 0.31), location: 0.00),
                                        Gradient.Stop(color: .black.opacity(0), location: 1.00),
                                        ],
                                        startPoint: UnitPoint(x: 0.5, y: 0),
                                        endPoint: UnitPoint(x: 0.5, y: 1)
                                        )
                                    )

                                VStack(alignment: .leading) {
                                    Text("2022")
                                    .font(.custom("DM Sans", size: geometry.size.height * 0.09).weight(.medium))
                                    .foregroundColor(.white)

                                    Text(yearOverYearListeningTime.totalPlayedTimeLastYear.storyTimeDescription)
                                    .font(.custom("DM Sans", size: geometry.size.height * 0.018).weight(.semibold))
                                    .padding(.top, -geometry.size.height * 0.08)
                                    .foregroundColor(.white)
                                }
                                .opacity(0.5)
                            }
                            .frame(height: leftBarPercentageSize * proxy.size.height)

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
                                    )

                                VStack(alignment: .leading) {
                                    Text("2023")
                                    .font(.custom("DM Sans", size: geometry.size.height * 0.09).weight(.medium))
                                    .foregroundColor(.white)

                                    Text(yearOverYearListeningTime.totalPlayedTimeThisYear.storyTimeDescription)
                                    .font(.custom("DM Sans", size: geometry.size.height * 0.018).weight(.semibold))
                                    .padding(.top, -geometry.size.height * 0.08)
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(height: rightBarPercentageSize * proxy.size.height)

                        }
                    }

                }
            }
            .background(.black)
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
            StoryShareableText("Shareable text")
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
    }
}
