import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct YearOverYearStory: ShareableStory {
    var duration: TimeInterval = 5.seconds

    let identifier: String = "year_over_year"

    let listeningPercentage = 10.3

    var title: String {
        switch listeningPercentage {
        case _ where listeningPercentage > 10:
            return L10n.eoyYearOverYearTitleWentUp("\(listeningPercentage)%")
        case _ where listeningPercentage < 0:
            return L10n.eoyYearOverYearTitleWentDown
        default:
            return L10n.eoyYearOverYearTitleFlat("\(listeningPercentage)%")
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
                    StoryLabel(title, for: .title, geometry: geometry)
                    StoryLabel(subtitle, for: .subtitle, color: Color(hex: "8F97A4"), geometry: geometry)
                }

                Spacer()

                Rectangle()
                    .frame(height: geometry.size.height * 0.1)
                    .opacity(0)
            }
            .background(
                ZStack(alignment: .bottom) {
                    Color.black

                    StoryGradient()
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
            StoryShareableText("Shareable text")
        ]
    }
}

struct YearOverYearStory_Previews: PreviewProvider {
    static var previews: some View {
        YearOverYearStory()
    }
}
