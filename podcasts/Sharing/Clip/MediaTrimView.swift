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
        static let trimHandleWidth: CGFloat = 17
        static let trimLineWidth: CGFloat = 4
        static let playLineWidth: CGFloat = 3
    }

    private enum Colors {
        static var trimBorderColor = Color(hex: "6B6B6B").opacity(0.28)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollableScrollView(scale: $scale,
                                 startTime: $startTime,
                                 endTime: $endTime,
                                 duration: duration,
                                 geometry: geometry,
                                 additionalEdgeOffsets: UIEdgeInsets(top: 0, left: Constants.trimHandleWidth, bottom: 0, right: (Constants.trimHandleWidth * 2) + Constants.trimLineWidth + Constants.playLineWidth)) { scrollable in
                AudioWaveformView(width: geometry.size.width * scale)
                    .border(Colors.trimBorderColor, width: Constants.trimLineWidth)
                PlayheadView(position: scaledPosition($playPosition), validRange: scaledPosition($startPosition).wrappedValue...scaledPosition($endPosition).wrappedValue)
                    .onChange(of: playTime) { playTime in
                        playPosition = durationRelative(value: playTime, for: geometry.size.width).clamped(to: startPosition...endPosition)
                    }
                    .onChange(of: playPosition) { playPosition in
                        playTime = (playPosition * duration) / geometry.size.width
                    }
                    .frame(width: Constants.playLineWidth)
                TrimSelectionView(leading: scaledPosition($startPosition), trailing: scaledPosition($endPosition), handleWidth: Constants.trimHandleWidth, indicatorWidth: Constants.playLineWidth, changed: { position, side in
                    update(position: position, for: side, in: geometry.size.width)
                })
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

        let playIndicatorWidth = Constants.playLineWidth / scale

        switch side {
        case .leading:
            range = 0...(endPosition - playIndicatorWidth)
        case .trailing:
            range = (startPosition + playIndicatorWidth)...width
        }

        let modifier: CGFloat
        switch side {
        case .leading:
            modifier = (Constants.trimHandleWidth / 2)
        case .trailing:
            modifier = -(Constants.trimHandleWidth / 2)
        }

        let scaledPosition = (position + modifier) / scale
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

        let endValue = (endPosition - playIndicatorWidth)
        if startPosition <= endValue {
            playPosition = playPosition.clamped(to: startPosition...endValue)
        }
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
