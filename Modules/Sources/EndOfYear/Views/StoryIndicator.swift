import SwiftUI
import PocketCastsUtils

public struct StoryIndicatorStyle {
    public let height: CGFloat
    public let borderRadius: CGFloat
    public let backgroundOpacity: CGFloat
    public let foregroundOpacity: CGFloat
    public let backgroundColor: Color
    public let foregroundColor: Color

    public init(
        height: CGFloat = 2,
        borderRadius: CGFloat = 5,
        backgroundOpacity: CGFloat = 0.3,
        foregroundOpacity: CGFloat = 0.9,
        backgroundColor: Color = .white,
        foregroundColor: Color = .white
    ) {
        self.height = height
        self.borderRadius = borderRadius
        self.backgroundOpacity = backgroundOpacity
        self.foregroundOpacity = foregroundOpacity
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
}

public struct StoryIndicator: View {
    let index: Int
    let style: StoryIndicatorStyle
    @ObservedObject var progressModel: StoriesProgressModel

    public init(index: Int, style: StoryIndicatorStyle = StoryIndicatorStyle(), progressModel: StoriesProgressModel) {
        self.index = index
        self.style = style
        self.progressModel = progressModel
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(style.backgroundColor)
                    .opacity(style.backgroundOpacity)
                    .cornerRadius(style.borderRadius)

                Rectangle()
                    .foregroundColor(style.foregroundColor)
                    .frame(width: geometry.size.width * (progressModel.progress - CGFloat(index)).clamped(to: 0.0 ..< 1.0), height: nil, alignment: .leading)
                    .opacity(style.foregroundOpacity)
                    .cornerRadius(style.borderRadius)
            }
        }
        .frame(height: style.height)
    }
}
