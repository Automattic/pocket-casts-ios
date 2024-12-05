import SwiftUI

struct ListeningTime2024Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool

    let listeningTime: Double

    private let foregroundColor = Color.black
    private let backgroundColor = Color(hex: "#EDB0F3")

    let identifier: String = "total_time"

    enum Constants {
        static let wayToGoStickerSize: CGSize = .init(width: 197, height: 165)
    }

    var body: some View {
        let components = listeningTime.components()
        let bigNumber = components.0
        let description = L10n.playback2024ListeningTimeDescription(components.1)

        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Spacer()
                ZStack {
                    VStack {
                        let isSmallScreen = geometry.size.height <= 500
                        let sizingFactor = isSmallScreen ? 0.7 : 0.9
                        let font = UIFont(name: "Humane-Bold", size: geometry.size.height * sizingFactor) ?? UIFont.systemFont(ofSize: geometry.size.height * sizingFactor)
                        Text("\(bigNumber)")
                            .lineLimit(1)
                            .font(Font(font as CTFont))
                            .minimumScaleFactor(0.5)
                            .offset(x: 0, y: font.lineHeight - font.capHeight)
                    }
                    Image("playback-sticker-way-to-go")
                        .resizable()
                        .frame(width: Constants.wayToGoStickerSize.width, height: Constants.wayToGoStickerSize.height)
                        .position(x: 21, y: 40, for: Constants.wayToGoStickerSize, in: geometry.frame(in: .local), corner: .topLeading)
                }
                StoryFooter2024(title: description, description: nil)
            }
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
            StoryShareableText(L10n.eoyStoryListenedToShareText(listeningTime.formattedTime() ?? ""), year: .y2024)
        ]
    }
}

fileprivate extension Double {
    private func dateComponents() -> DateComponents {
        let calendar = Calendar.current
        let referenceDate = Date(timeIntervalSinceReferenceDate: TimeInterval(self))

        return calendar.dateComponents([.day, .hour, .minute, .second], from: Date(timeIntervalSinceReferenceDate: 0), to: referenceDate)
    }

    func components() -> (String, String) {
        guard let timeString = formattedTime() else {
            return ("0", "Unknown time")
        }

        let stringComponents = timeString.components(separatedBy: " ")
        let modifiedComponents = stringComponents.suffix(from: 1).joined(separator: " ")
        return (stringComponents.first ?? "0", modifiedComponents.replacingOccurrences(of: ",", with: ""))
    }

    func formattedTime() -> String? {
        let components = dateComponents()
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 3
        formatter.allowsFractionalUnits = false
        formatter.allowedUnits = [.day, .hour, .minute, .second]

        if let days = components.day {
            if days > 3 {
                formatter.allowedUnits = [.day, .hour, .minute]
            } else {
                formatter.allowedUnits = [.hour, .minute]
            }
        } else if let hours = components.hour, hours != 0 {
            formatter.allowedUnits = [.hour, .minute]
        } else if let minutes = components.minute, minutes != 0 {
            formatter.allowedUnits = [.minute]
        } else if let seconds = components.second, seconds != 0 {
            formatter.allowedUnits = [.second]
        }

        return formatter.string(from: components)
    }
}

#Preview("Days") {
    ListeningTime2024Story(listeningTime: 4.day + 5.hour + 20.minutes)
}

#Preview("Days hour min") {
    ListeningTime2024Story(listeningTime: 1.day + 5.hour + 20.minutes)
}

#Preview("Day and min") {
    ListeningTime2024Story(listeningTime: 1.day + 20.minutes)
}

#Preview("Hours") {
    ListeningTime2024Story(listeningTime: 5.hours + 20.minutes)
}

#Preview("Minutes") {
    ListeningTime2024Story(listeningTime: 60)
}

#Preview("Seconds") {
    ListeningTime2024Story(listeningTime: 30)
}

#Preview("Zero") {
    ListeningTime2024Story(listeningTime: 0)
}
