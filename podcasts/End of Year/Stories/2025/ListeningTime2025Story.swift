import SwiftUI
import Lottie

struct ListeningTime2025Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool

    let listeningTime: Double

    private let foregroundColor = Color.white
    private let backgroundColor = Color.endOfYear2025Background

    let identifier: String = "total_time"

    var formattedMinutes: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(for: Int(listeningTime / 60.0)) ?? ""
    }

    var body: some View {
        let bigNumber = formattedMinutes

        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading) {
                    Spacer()
                    let sizingFactor = 0.25
                    let font = UIFont(name: "Humane-SemiBold", size: geometry.size.height * sizingFactor) ?? UIFont.systemFont(ofSize: geometry.size.height * sizingFactor)
                    Text("\(bigNumber)")
                        .lineLimit(1)
                        .font(Font(font as CTFont))
                        .minimumScaleFactor(0.5)
                        .offset(x: 0, y: font.lineHeight - font.capHeight)
                    HStack {
                        Text("minutes listened")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .kerning(0.54)
                            .padding(.vertical, (listeningTime < 60 * 1000) ? -font.descender / 2  : -font.descender)
                        Spacer()
                    }
                }
                .padding(.bottom, geometry.size.height * 0.17)
                .padding(.horizontal, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(content: {
                if renderForSharing {
                    Image("listened_numbers_2025_back")
                        .resizable()
                        .scaledToFit()
                } else {
                    LottieView(animation: .named("playback2025_listening_time"))
                        .animationDidFinish({ completed in
                        })
                        .configure({ animationView in
                            animationView.contentMode = .scaleToFill
                        })
                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .autoReverse)))
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            })
        }
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .enableProportionalValueScaling()
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
            StoryShareableText(L10n.eoyStoryListenedToShareText(formattedMinutes), year: .y2025)
        ]
    }
}

#Preview("Days") {
    ListeningTime2025Story(listeningTime: 4.day + 5.hour + 20.minutes)
}

#Preview("Days hour min") {
    ListeningTime2025Story(listeningTime: 1.day + 5.hour + 20.minutes)
}

#Preview("Day and min") {
    ListeningTime2025Story(listeningTime: 1.day + 20.minutes)
}

#Preview("Hours") {
    ListeningTime2025Story(listeningTime: 5.hours + 20.minutes)
}

#Preview("Minutes") {
    ListeningTime2025Story(listeningTime: 60)
}

#Preview("Seconds") {
    ListeningTime2025Story(listeningTime: 30)
}

#Preview("Zero") {
    ListeningTime2025Story(listeningTime: 0)
}
