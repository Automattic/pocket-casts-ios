import SwiftUI

struct StoryIndicator: View {
    @ObservedObject private var model = StoriesProgressModel.shared

    let index: Int

    var body: some View {
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.white.opacity(Constants.storyIndicatorBackgroundOpacity))
                        .cornerRadius(Constants.storyIndicatorBorderRadius)

                    Rectangle()
                        .frame(width: geometry.size.width * (min(max((CGFloat(model.progress) - CGFloat(index)), 0.0), 1.0)), height: nil, alignment: .leading)
                        .foregroundColor(Color.white.opacity(Constants.storyIndicatorForegroundOpacity))
                        .cornerRadius(Constants.storyIndicatorBorderRadius)
                }
            }
    }

    struct Constants {
        static let storyIndicatorBorderRadius: CGFloat = 5
        static let storyIndicatorBackgroundOpacity: CGFloat = 0.3
        static let storyIndicatorForegroundOpacity: CGFloat = 0.9
    }
}
