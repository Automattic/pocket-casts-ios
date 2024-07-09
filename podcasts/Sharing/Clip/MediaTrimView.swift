import SwiftUI
import AVFoundation

struct MediaTrimView: View {
    let duration: TimeInterval

    @Binding var startTime: TimeInterval
    @Binding var endTime: TimeInterval
    @Binding var playTime: TimeInterval

    @State private var scale: CGFloat = .zero
    @State private var playPosition: CGFloat = 0

    private enum Constants {
        static let trimLineWidth: CGFloat = 4
        static let playLineWidth: CGFloat = 3
    }

    private enum Colors {
        static var trimBorderColor = Color(hex: "6B6B6B")
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollableScrollView(scale: $scale, duration: duration, geometry: geometry) { scrollable in
                AudioWaveformView(scale: scale, width: geometry.size.width * scale)
                borderView(in: geometry)
                PlayheadView(position: scaledPosition($playPosition), onChanged: {
                    print("Moved playhead to: \($0)")
                })
                    .frame(maxHeight: .infinity)
                    .frame(width: Constants.playLineWidth)
                    .onAppear {
                        initializePositions(in: geometry)
                        DispatchQueue.main.async {
                            let currentSecond = Int(playTime)
                            scrollable.scrollTo("\(currentSecond)", anchor: .center)
                        }
                    }
                    .onChange(of: playTime) { _ in
                        //TODO: Change this to listen to the play/pause event?
                        let currentSecond = Int(playTime)
                        scrollable.scrollTo("\(currentSecond)", anchor: .center)
                        playPosition = durationRelative(value: playTime, for: geometry.size.width)
                    }
                .onAppear {
                    initializePositions(in: geometry)
                    DispatchQueue.main.async {
                        let currentSecond = Int(startTime)
                        scrollable.scrollTo("\(currentSecond)", anchor: .center)
                    }
                }
            }
        }
    }

    private func borderView(in geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.clear)
            .border(Colors.trimBorderColor.opacity(0.28), width: Constants.trimLineWidth)
    }

    private func scaledPosition(_ position: Binding<CGFloat>) -> Binding<CGFloat> {
        Binding<CGFloat>(
            get: { position.wrappedValue * scale },
            set: { newValue in
                position.wrappedValue = newValue / scale
            }
        )
    }

    private func initializePositions(in geometry: GeometryProxy) {
        let viewWidth = geometry.size.width
        updatePositions(for: viewWidth)

        let zoomScale = initialScale / 2
        scale = zoomScale
    }

    private func updatePositions(for width: CGFloat) {
        playPosition = durationRelative(value: playTime, for: width)
    }

    private var initialScale: CGFloat {
        let visibleDuration = endTime - startTime
        let fullDuration = duration
        let durationRatio = fullDuration / visibleDuration

        // The scale should make the visible duration fit the view width
        let scale = durationRatio / 2

        return max(scale, 1.0)
    }

    private func durationRelative(value: CGFloat, for width: CGFloat) -> CGFloat {
        return (value / duration) * width
    }
}

struct MediaTrimView_Previews: PreviewProvider {
    static var previews: some View {
        MediaTrimView(
            duration: 60,
            startTime: .constant(.zero),
            endTime: .constant(30),
            playTime: .constant(15)
        )
    }
}
