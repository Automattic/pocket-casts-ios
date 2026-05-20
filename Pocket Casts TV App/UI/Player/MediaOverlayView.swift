import SwiftUI

struct MediaOverlayView: View {

    @Bindable var model: NowPlayingViewModel
    @Binding var isTransportBarVisible: Bool

    enum Layout {
        static let podcastImageSize = CGFloat(640)
    }

    var scale: CGFloat {
        return isTransportBarVisible ? 3.0 : 2.0
    }

    var body: some View {
        GeometryReader() { proxy in
            if !model.isVideo, let uiImage = model.displayImage {
                VStack(alignment: .center) {
                    if isTransportBarVisible {
                        Spacer().frame(height: 100)
                    } else {
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: proxy.size.height / scale, height: proxy.size.height / scale)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .blurredCoverBackground(size: proxy.size.height / scale) {
                                Image(uiImage: uiImage)
                            }
                            .animation(.smooth, value: isTransportBarVisible)
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
