import SwiftUI

struct MediaOverlayView: View {

    @Bindable var model = NowPlayingViewModel()

    enum Layout {
        static let podcastImageSize = CGFloat(640)
    }

    var body: some View {
        GeometryReader() { proxy in
            if !model.isVideo, let uiImage = model.displayImage {
                VStack(alignment: .center) {
                    Spacer()
                        .frame(height: 100)
                    HStack {
                        Spacer()
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: proxy.size.height / 2.0, height: proxy.size.height / 2.0)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .blurredCoverBackground(size: proxy.size.height / 2.0) {
                                Image(uiImage: uiImage)
                            }
                            .animation(.smooth, value: proxy.size.height)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .task {
            model.load()
        }
    }
}
