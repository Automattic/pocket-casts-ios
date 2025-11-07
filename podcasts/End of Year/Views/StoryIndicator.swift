import SwiftUI

struct StoryIndicator: View {
    @ObservedObject private var model = StoriesProgressModel.shared

    let index: Int

    var body: some View {
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .opacity(Constants.storyIndicatorBackgroundOpacity)
                        .cornerRadius(Constants.storyIndicatorBorderRadius)

                    Rectangle()
                        .frame(width: geometry.size.width * (model.progress - CGFloat(index)).clamped(to: 0.0 ..< 1.0), height: nil, alignment: .leading)
                        .opacity(Constants.storyIndicatorForegroundOpacity)
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
