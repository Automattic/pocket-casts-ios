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
            ZStack {
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

                if model.isLoading {
                    loadingOverlay
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: model.isLoading)
        }
        .ignoresSafeArea()
    }

    private var loadingOverlay: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.3)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
