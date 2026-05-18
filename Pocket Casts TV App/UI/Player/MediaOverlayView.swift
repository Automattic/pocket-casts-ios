import SwiftUI

struct MediaOverlayView: View {

    @Bindable var model = NowPlayingViewModel()

    enum Layout {
        static let podcastImageSize = CGFloat(418)
    }

    var body: some View {
        VStack {
            Spacer()
            if !model.isVideo {
                if let uiImage = model.displayImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: Layout.podcastImageSize, height: Layout.podcastImageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            Spacer()
        }
        .padding()
        .task {
            model.load()
        }
    }
}
