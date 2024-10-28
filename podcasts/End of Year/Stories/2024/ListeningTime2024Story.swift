import SwiftUI

struct ListeningTime2024Story: ShareableStory {
    @Environment(\.renderForSharing) var renderForSharing: Bool

    let listeningTime: Double

    private let backgroundColor = Color(hex: "#EDB0F3")

    enum Constants {
        static let wayToGoStickerSize: CGSize = .init(width: 197, height: 165)
    }

    var body: some View {
        let components = listeningTime.components()
        let bigNumber = components.0
        let description = L10n.playback2024ListeningTimeDescription(components.1)

        GeometryReader { geometry in
            ZStack {
                VStack {
                    Text("\(bigNumber)")
                        .lineLimit(1)
                        .font(.custom("Humane-Bold", size: geometry.size.height * 0.7))
                    Text(description)
                        .font(.system(size: 30, weight: .bold))
                        .padding(.horizontal, 6)
                        .minimumScaleFactor(0.8)
                }
                Image("playback-sticker-way-to-go")
                    .resizable()
                    .frame(width: Constants.wayToGoStickerSize.width, height: Constants.wayToGoStickerSize.height)
                    .position(x: 21, y: 52, for: Constants.wayToGoStickerSize, in: geometry.frame(in: .local), corner: .topLeading)
            }
        }
        .background(backgroundColor)
        .enableProportionalValueScaling()
    }

    func sharingAssets() -> [Any] {
        [
            StoryShareableProvider.new(AnyView(self)),
            StoryShareableText(L10n.eoyStoryListenedToShareText(listeningTime.storyTimeDescriptionForSharing))
        ]
    }
}

fileprivate extension Double {
    private func dateComponents() -> DateComponents {
        let calendar = Calendar.current
        let seconds = Int(self)
        let referenceDate = Date(timeIntervalSinceReferenceDate: TimeInterval(seconds))

        return calendar.dateComponents([.day, .hour, .minute, .second], from: referenceDate)
    }

    func components() -> (String, String) {
        let components = dateComponents()
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        formatter.allowsFractionalUnits = false
        formatter.allowedUnits = [.day, .hour, .minute, .second]

        if let days = components.day, days != 0 {
            if let hours = components.hour, hours != 0 {
                formatter.allowedUnits = [.day, .hour]
            } else {
                formatter.allowedUnits = [.day]
            }
        } else if let hours = components.hour, hours != 0 {
            formatter.allowedUnits = [.hour]
        } else if let minutes = components.minute, minutes != 0 {
            formatter.allowedUnits = [.minute]
        } else if let seconds = components.second, seconds != 0 {
            formatter.allowedUnits = [.second]
        }

        if let timeString = formatter.string(from: components) {
            let stringComponents = timeString.components(separatedBy: " ")
            let modifiedComponents = stringComponents.suffix(from: 1).joined(separator: " ")
            return (stringComponents.first ?? "0", modifiedComponents.replacingOccurrences(of: ",", with: ""))
        } else {
            return ("0", "Unknown time")
        }
    }
}

#Preview("Days") {
    ListeningTime2024Story(listeningTime: 500*60)
}

#Preview("Hours") {
    ListeningTime2024Story(listeningTime: 60)
}
