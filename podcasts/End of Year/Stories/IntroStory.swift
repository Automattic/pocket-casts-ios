import SwiftUI

struct IntroStory: StoryView {
    var duration: TimeInterval = 5.seconds
    let identifier: String = "intro"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Image("2022_big")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top, geometry.size.height * Constants.imageVerticalPadding)

                    let title = L10n.eoyStoryIntroTitle.replacingOccurrences(of: "...", with: "!")
                    StoryLabel(title, for: .title)
                        .padding(.top, Constants.spaceBetweenImageAndText)

                    Spacer()
                }
            }
            .background(Color(hex: "#1A1A1A"))
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: identifier)
    }

    private struct Constants {
        // Percentage based on total view height
        static let imageVerticalPadding = 0.10

        static let spaceBetweenImageAndText = 24.0

        static let fontSize = 22.0
        static let textHorizontalPadding = 35.0
    }
}

struct IntroStory_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory()
    }
}
