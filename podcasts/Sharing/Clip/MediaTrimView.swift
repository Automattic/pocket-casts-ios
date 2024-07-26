import SwiftUI
import AVFoundation

struct MediaTrimView: View {
    let duration: TimeInterval

    @Binding var startTime: TimeInterval
    @Binding var endTime: TimeInterval
    @Binding var playTime: TimeInterval

    @State private var scale: CGFloat = .zero

    @State private var startPosition: CGFloat = 0
    @State private var endPosition: CGFloat = 1
    @State private var playPosition: CGFloat = 0

    private enum Constants {
        static let trimLineWidth: CGFloat = 4
        static let playLineWidth: CGFloat = 3
    }

    private enum Colors {
        static var trimBorderColor = Color(hex: "6B6B6B").opacity(0.28)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollableScrollView(scale: $scale, duration: duration, geometry: geometry) { scrollable in
                AudioWaveformView(scale: scale, width: geometry.size.width * scale)
                borderView(in: geometry)
                PlayheadView(position: scaledPosition($playPosition), validRange: scaledPosition($startPosition).wrappedValue...scaledPosition($endPosition).wrappedValue)
                    .onChange(of: playTime) { playTime in
                        playPosition = durationRelative(value: playTime, for: geometry.size.width)
                    }
                    .onChange(of: playPosition) { playPosition in
                        playTime = (playPosition * duration) / geometry.size.width
                    }
                    .frame(width: Constants.playLineWidth)
                TrimSelectionView(leading: scaledPosition($startPosition), trailing: scaledPosition($endPosition), changed: { position, side in
                    update(position: position, for: side, in: geometry.size.width)
                })
                .onAppear {
                    initializePositions(in: geometry)
                    DispatchQueue.main.async {
                        let currentSecond = Int(playTime)
                        scrollable.scrollTo("\(currentSecond)", anchor: .center)
                    }
                }
                .onAppear {
                    initializePositions(in: geometry)
                    DispatchQueue.main.async {
                        let currentSecond = Int(startTime + (endTime - startTime) / 2)
                        scrollable.scrollTo("\(currentSecond)", anchor: .center)
                    }
                }
            }
        }
    }

    private func borderView(in geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.clear)
            .border(Colors.trimBorderColor, width: Constants.trimLineWidth)
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
        startPosition = durationRelative(value: startTime, for: width)
        endPosition = durationRelative(value: endTime, for: width)
        playPosition = durationRelative(value: playTime, for: width)
    }

    private var initialScale: CGFloat {
        let visibleDuration = endTime - startTime
        let fullDuration = duration
        let durationRatio = fullDuration / visibleDuration

        // The scale should make the visible duration fit the view width
        let scale = durationRatio

        return max(scale, 1.0)
    }

    private func durationRelative(value: CGFloat, for width: CGFloat) -> CGFloat {
        return (value / duration) * width
    }

    /// Updates the position of the trim handles
    /// - Parameters:
    ///   - position: The raw position of a trim handle
    ///   - side: The trim handle's side (leading or trailing)
    ///   - width: The width of the containing view to constrain to min and max values
    private func update(position: CGFloat, for side: TrimHandle.Side, in width: CGFloat) {
        let range: ClosedRange<CGFloat>

        switch side {
        case .leading:
            range = 0...endPosition
        case .trailing:
            range = startPosition...width
        }

        let scaledPosition = position / scale
        let newPosition = scaledPosition.clamped(to: range)

        let time = Double(newPosition / width) * duration

        switch side {
        case .leading:
            startTime = time
            startPosition = newPosition
        case .trailing:
            endTime = time
            endPosition = newPosition
        }

        playTime = playTime.clamped(to: startTime...endTime)
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
