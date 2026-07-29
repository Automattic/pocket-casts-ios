import SwiftUI

struct MediaOverlayView: View {

    @Bindable var model: NowPlayingViewModel
    @Binding var isTransportBarVisible: Bool

    enum Layout {
        static let artworkSize = CGFloat(360)
    }

    var scale: CGFloat {
        return isTransportBarVisible ? 3.0 : 2.0
    }

    var body: some View {
        //GeometryReader() { proxy in
            ZStack {
                if !model.isVideo || model.isFirstLoad || model.isFailed, let uiImage = model.displayImage {
                    VStack(alignment: .center) {
                        if isTransportBarVisible {
                            Spacer().frame(height: 100)
                        } else {
                            Spacer().frame(height: 256)
                        }
                        HStack(spacing: 64) {
                            Spacer()
                            if !model.isVideo, !model.isFirstLoad, model.isPlaying {
                                PlayerAudioWaveformView(audioMeter: AudioMeterManager.shared, barCount: 12, barWidth: 14, barSpacing: 20, primaryColor: Color.white.opacity(0.12), secondaryColor: Color.white.opacity(0.12))
                                    .frame(width: Layout.artworkSize, height: Layout.artworkSize)
                                    .transition(.opacity)
                                    .animation(.smooth, value: isTransportBarVisible)
                                    //.border(.red)
                            }
                            ZStack(alignment: .center) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: Layout.artworkSize, height: Layout.artworkSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .blurredCoverBackground(size: Layout.artworkSize, opacity: 0.5) {
                                        Image(uiImage: uiImage)
                                    }
                            }
                            if !model.isVideo, !model.isFirstLoad, model.isPlaying {
                                PlayerAudioWaveformView(audioMeter: AudioMeterManager.shared, barCount: 12, barWidth: 14, barSpacing: 16, primaryColor: Color.white.opacity(0.12), secondaryColor: Color.white.opacity(0.12))
                                    .frame(width: Layout.artworkSize, height: Layout.artworkSize)
                                    .transition(.opacity)
                                    .animation(.smooth, value: isTransportBarVisible)
                                    //.border(.red)
                            }
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
            .animation(.smooth(duration: 0.2), value: model.isPlaying)
            .background(model.isVideo && !model.isFirstLoad && !model.isFailed ? Color.clear : Color.pcBackgroundBase)
        //}
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
