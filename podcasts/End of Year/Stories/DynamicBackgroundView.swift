import SwiftUI
import PocketCastsDataModel

struct DynamicBackgroundView: View {
    let backgroundColor: Color
    let foregroundColor: Color

    init(podcast: Podcast) {
        backgroundColor = podcast.bgColor().color
        foregroundColor = ColorManager.lightThemeTintForPodcast(podcast).color
    }

    init(backgroundColor: Color, foregroundColor: Color) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        ZStack {
            backgroundColor

            Color.black.opacity(0.2)

            VStack {
                Image("top_blob")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color.white)
                    .opacity(0.5)
            }

            VStack {
                Image("bottom_blob")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(foregroundColor)
            }

        }
    }
}

struct DynamicBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicBackgroundView(podcast: Podcast.previewPodcast())
    }
}
