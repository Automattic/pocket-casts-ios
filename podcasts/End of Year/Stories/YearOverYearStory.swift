import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct YearOverYearStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "year_over_year"

    let listeningPercentage = 7.5

    let subscriptionTier: SubscriptionTier = .plus

    var title: String {
        switch listeningPercentage {
        case _ where listeningPercentage > 10:
            return L10n.eoyYearOverYearTitleWentUp("\(listeningPercentage)%")
        case _ where listeningPercentage < 0:
            return L10n.eoyYearOverYearTitleWentDown
        default:
            return L10n.eoyYearOverYearTitleFlat
        }
    }

    var subtitle: String {
        switch listeningPercentage {
        case _ where listeningPercentage > 10:
            return L10n.eoyYearOverYearSubtitleWentUp
        case _ where listeningPercentage < 0:
            return L10n.eoyYearOverYearSubtitleWentDown
        default:
            return L10n.eoyYearOverYearSubtitleFlat
        }
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
                    HStack(alignment: .bottom, spacing: 0) {
                        ZStack(alignment: .top) {
                            Rectangle()
                                .foregroundColor(.clear)
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

                                Text("10 days 2 hours")
                                .font(.custom("DM Sans", size: geometry.size.height * 0.018).weight(.semibold))
                                .foregroundColor(.white)
                            }
                            .opacity(0.5)
                        }

                        ZStack(alignment: .top) {
                            Rectangle()
                                .foregroundColor(.clear)
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

                                Text("10 days 2 hours")
                                .font(.custom("DM Sans", size: geometry.size.height * 0.018).weight(.semibold))
                                .foregroundColor(.white)
                            }
                        }
                    }

                    Rectangle()
                      .foregroundColor(.clear)
                      .frame(width: 393, height: geometry.size.height * 0.35)
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

struct YearOverYearStory_Previews: PreviewProvider {
    static var previews: some View {
        YearOverYearStory()
    }
}
