import SwiftUI

struct MediaOverlayView: View {

    @Bindable var model: NowPlayingViewModel
    @Binding var isTransportBarVisible: Bool

    enum Layout {
        static let artworkSize = CGFloat(360)
    }

    var body: some View {
        GeometryReader() { proxy in
            ZStack {
                if !model.isVideo || model.isFirstLoad || model.isFailed, let uiImage = model.displayImage {
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
                                .frame(width: Layout.artworkSize, height: Layout.artworkSize)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .accessibilityHidden(true)
                                .blurredCoverBackground(size: Layout.artworkSize, radius: 100, scale: 1.5, offset: -0.5) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .accessibilityHidden(true)
                                }
                                .background {
                                    NowPlayingWaveformView(
                                        color: .pcTextPrimary.opacity(0.8),
                                        isAnimating: model.isPlaying,
                                        artworkSize: Layout.artworkSize
                                    )
                                    .frame(width: proxy.size.width * 0.75)
                                }
                                .animation(.smooth, value: isTransportBarVisible)
                            Spacer()
                        }
                        if model.isFailed {
                            failureOverlay
                                .transition(.opacity)
                        }
                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            if model.isFailed {
                                failureOverlay
                                    .transition(.opacity)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }

                if model.isLoading, !model.isFailed {
                    loadingOverlay
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: model.isLoading)
            .animation(.easeInOut(duration: 0.2), value: model.isFailed)
            .background(model.isVideo && !model.isFirstLoad && !model.isFailed ? Color.clear : Color.pcBackgroundBase)
        }
        .ignoresSafeArea()
    }

    private var loadingOverlay: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .scaleEffect(1.3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var failureOverlay: some View {
        Text(model.errorMessage)
            .font(.caption)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .glassEffect(.regular)
    }
}
