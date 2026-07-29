import SwiftUI

class NowPlayingWaveformModel: ObservableObject {
    @Published var isAnimating: Bool = false
    @Published var color: Color = .white
}

struct NowPlayingWaveformView: View {
    @ObservedObject var model: NowPlayingWaveformModel

    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 5
    private let maxBarHeight: CGFloat = 30

    var body: some View {
        TimelineView(.animation(paused: !model.isAnimating)) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let artworkSize = min(size.width, size.height) * 0.85
                let artworkHalf = artworkSize / 2

                let sideWidth = (size.width - artworkSize) / 2
                let barsPerSide = Int(sideWidth / (barWidth + barSpacing))

                let time = model.isAnimating ? timeline.date.timeIntervalSinceReferenceDate : 0

                for side in 0..<2 {
                    for i in 0..<barsPerSide {
                        let normalizedIndex = CGFloat(i) / CGFloat(max(1, barsPerSide - 1))
                        // Bars taller near artwork, shorter at edges
                        let distanceFactor = side == 0 ? normalizedIndex : (1.0 - normalizedIndex)
                        let wave = sin(time * 2.5 + Double(i) * 0.4) * 0.5 + 0.5
                        let height = maxBarHeight * distanceFactor * CGFloat(wave)

                        let x: CGFloat
                        if side == 0 {
                            x = centerX - artworkHalf - CGFloat(barsPerSide - i) * (barWidth + barSpacing)
                        } else {
                            x = centerX + artworkHalf + CGFloat(i) * (barWidth + barSpacing) + barSpacing
                        }

                        var path = Path()
                        path.addRoundedRect(
                            in: CGRect(x: x, y: centerY - height / 2, width: barWidth, height: max(2, height)),
                            cornerSize: CGSize(width: 1.5, height: 1.5)
                        )
                        context.fill(path, with: .color(model.color.opacity(0.6 * Double(distanceFactor))))
                    }
                }
            }
            .blur(radius: 6)
            .allowsHitTesting(false)
        }
    }
}
