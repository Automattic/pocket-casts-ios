import SwiftUI

struct IntroStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Image("2022_big")
                        .resizable()
                        .scaledToFill()
                        .frame(height: geometry.size.height * Constants.imageHeightInPercentage)
                        .padding(.top, Constants.imageVerticalPadding)
                        .padding(.bottom, Constants.imageVerticalPadding)
                    Text(L10n.eoyStoryIntroTitle)
                        .font(.system(size: Constants.fontSize, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, Constants.textHorizontalPadding)
                        .padding(.trailing, Constants.textHorizontalPadding)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: geometry.size.height * Constants.textMaxHeightInPercentage)
                        .minimumScaleFactor(Constants.textMinimumScaleFactor)
                    Spacer()
                    Image("logo_white")
                        .padding(.bottom, Constants.logoBottomPadding)
                }
            }
            .background(UIColor(hex: "#1A1A1A").color)
        }
    }

    func onAppear() {
        Analytics.track(.endOfYearStoryShown, story: .intro)
    }

    func willShare() {
        Analytics.track(.endOfYearStoryShare, story: .intro)
    }

    func sharingAssets() -> [Any] {
        [StoryShareableProvider.new(AnyView(self)), "#pocketcasts #endofyear2022"]
    }

    private struct Constants {
        static let imageVerticalPadding: CGFloat = 60
        static let imageHeightInPercentage: CGFloat = 0.54

        static let fontSize: CGFloat = 40
        static let textHorizontalPadding: CGFloat = 35
        static let textMaxHeightInPercentage: CGFloat = 0.07
        static let textMinimumScaleFactor: CGFloat = 0.01

        static let logoBottomPadding: CGFloat = 40
    }
}

struct IntroStory_Previews: PreviewProvider {
    static var previews: some View {
        IntroStory()
    }
}
