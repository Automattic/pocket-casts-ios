import SwiftUI

struct NowPlayingWaveformView: View {
    let color: Color
    let isAnimating: Bool

    @State private var amplitude: CGFloat = 0

    private let barWidth: CGFloat = 5
    private let barSpacing: CGFloat = 7
    private let maxBarHeight: CGFloat = 80

    var body: some View {
        // Always keep the timeline running so bars animate smoothly to zero
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let artworkSize = min(size.width, size.height) * 0.85
                let artworkHalf = artworkSize / 2

                let sideWidth = (size.width - artworkSize) / 2
                let barsPerSide = Int(sideWidth / (barWidth + barSpacing))

                let time = timeline.date.timeIntervalSinceReferenceDate

                for side in 0..<2 {
                    for i in 0..<barsPerSide {
                        let normalizedIndex = CGFloat(i) / CGFloat(max(1, barsPerSide - 1))
                        let distanceFactor = side == 0 ? normalizedIndex : (1.0 - normalizedIndex)
                        let wave = sin(time * 2.5 + Double(i) * 0.4) * 0.5 + 0.5
                        let height = maxBarHeight * distanceFactor * CGFloat(wave) * amplitude

                        let x: CGFloat
                        if side == 0 {
                            x = centerX - artworkHalf - CGFloat(barsPerSide - i) * (barWidth + barSpacing)
                        } else {
                            x = centerX + artworkHalf + CGFloat(i) * (barWidth + barSpacing) + barSpacing
                        }

                        var path = Path()
                        path.addRoundedRect(
                            in: CGRect(x: x, y: centerY - height / 2, width: barWidth, height: max(2, height)),
                            cornerSize: CGSize(width: 2, height: 2)
                        )
                        context.fill(path, with: .color(color.opacity(0.8 * Double(distanceFactor) * Double(amplitude))))
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .onChange(of: isAnimating) { _, newValue in
            withAnimation(.easeInOut(duration: 2.0)) {
                amplitude = newValue ? 1 : 0
            }
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 2.0)) {
                    amplitude = 1
                }
            }
        }
    }
}
