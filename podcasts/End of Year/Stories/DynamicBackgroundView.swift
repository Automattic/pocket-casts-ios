import SwiftUI
import PocketCastsDataModel

struct DynamicBackgroundView: View {
    let podcast: Podcast

    var body: some View {
        ZStack {
            podcast.bgColor().color

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
                    .foregroundColor(ColorManager.lightThemeTintForPodcast(podcast).color)
            }

        }
    }
}

struct DynamicBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicBackgroundView(podcast: Podcast.previewPodcast())
    }
}
