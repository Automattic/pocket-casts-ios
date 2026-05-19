import SwiftUI

struct MediaOverlayView: View {

    @Bindable var model = NowPlayingViewModel()

    enum Layout {
        static let podcastImageSize = CGFloat(640)
    }

    var body: some View {
        Group {
            if !model.isVideo, let uiImage = model.displayImage {
                GeometryReader() { proxy in
                    VStack(alignment: .center) {
                        Spacer()
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
        }
        .task {
            model.load()
        }
    }
}
