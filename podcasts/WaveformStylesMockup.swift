import SwiftUI

// MARK: - Style 1: Soft Radial Glow Bars

struct GlowBarsWaveformView: View {
    @State private var phase: CGFloat = 0
    let color: Color
    let barCount = 40
    let isAnimating: Bool

    var body: some View {
        TimelineView(.animation(paused: !isAnimating)) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let artworkSize = min(size.width, size.height) * 0.7
                let artworkHalf = artworkSize / 2

                // Draw bars on left and right sides
                let barWidth: CGFloat = 3
                let barSpacing: CGFloat = 5
                let maxBarHeight: CGFloat = 30
                let sideWidth = (size.width - artworkSize) / 2
                let barsPerSide = Int(sideWidth / (barWidth + barSpacing))

                let time = isAnimating ? timeline.date.timeIntervalSinceReferenceDate : 0

                for side in [0, 1] {
                    for i in 0..<barsPerSide {
                        let normalizedIndex = CGFloat(i) / CGFloat(max(1, barsPerSide - 1))
                        // Bars taller near artwork, shorter at edges
                        let distanceFactor = side == 0 ? normalizedIndex : (1.0 - normalizedIndex)
                        let wave = sin(time * 2.5 + Double(i) * 0.4) * 0.5 + 0.5
                        let height = maxBarHeight * distanceFactor * CGFloat(wave)

                        let x: CGFloat
                        if side == 0 {
                            // Left side
                            x = centerX - artworkHalf - CGFloat(barsPerSide - i) * (barWidth + barSpacing)
                        } else {
                            // Right side
                            x = centerX + artworkHalf + CGFloat(i) * (barWidth + barSpacing) + barSpacing
                        }

                        var path = Path()
                        path.addRoundedRect(
                            in: CGRect(x: x, y: centerY - height / 2, width: barWidth, height: max(2, height)),
                            cornerSize: CGSize(width: 1.5, height: 1.5)
                        )
                        context.fill(path, with: .color(color.opacity(0.6 * Double(distanceFactor))))
                    }
                }

                // Draw bars on top and bottom
                let verticalBarsCount = Int(artworkSize / (barWidth + barSpacing))
                for side in [0, 1] {
                    for i in 0..<verticalBarsCount {
                        let normalizedIndex = CGFloat(i) / CGFloat(max(1, verticalBarsCount - 1))
                        let centerFactor = 1.0 - abs(normalizedIndex - 0.5) * 2.0
                        let wave = sin(time * 2.5 + Double(i) * 0.3 + 1.5) * 0.5 + 0.5
                        let height = maxBarHeight * centerFactor * CGFloat(wave)

                        let x = centerX - artworkHalf + CGFloat(i) * (barWidth + barSpacing)
                        let y: CGFloat
                        if side == 0 {
                            // Top
                            y = centerY - artworkHalf - height
                        } else {
                            // Bottom
                            y = centerY + artworkHalf
                        }

                        var path = Path()
                        path.addRoundedRect(
                            in: CGRect(x: x, y: y, width: barWidth, height: max(2, height)),
                            cornerSize: CGSize(width: 1.5, height: 1.5)
                        )
                        context.fill(path, with: .color(color.opacity(0.5 * Double(centerFactor))))
                    }
                }
            }
            .blur(radius: 8)
        }
    }
}

// MARK: - Style 2: Concentric Ripple Rings

struct RippleRingsWaveformView: View {
    let color: Color
    let isAnimating: Bool
    let ringCount = 4

    var body: some View {
        TimelineView(.animation(paused: !isAnimating)) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let artworkSize = min(size.width, size.height) * 0.7
                let artworkHalf = artworkSize / 2
                let cornerRadius: CGFloat = 8

                let time = isAnimating ? timeline.date.timeIntervalSinceReferenceDate : 0

                for i in 0..<ringCount {
                    let ringPhase = (time * 0.8 + Double(i) * 0.7).truncatingRemainder(dividingBy: Double(ringCount) * 0.7)
                    let expansion = CGFloat(ringPhase / (Double(ringCount) * 0.7)) * 30
                    let opacity = max(0, 1.0 - Double(expansion / 30))

                    let rect = CGRect(
                        x: centerX - artworkHalf - expansion,
                        y: centerY - artworkHalf - expansion,
                        width: artworkSize + expansion * 2,
                        height: artworkSize + expansion * 2
                    )
                    let path = Path(roundedRect: rect, cornerRadius: cornerRadius + expansion * 0.3)

                    context.stroke(
                        path,
                        with: .color(color.opacity(opacity * 0.4)),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

// MARK: - Style 3: Organic Sine Wave

struct SineWaveWaveformView: View {
    let color: Color
    let isAnimating: Bool

    var body: some View {
        TimelineView(.animation(paused: !isAnimating)) { timeline in
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let artworkSize = min(size.width, size.height) * 0.7
                let artworkHalf = artworkSize / 2
                let margin: CGFloat = 12

                let time = isAnimating ? timeline.date.timeIntervalSinceReferenceDate : 0

                // Draw sine waves on each side
                for layer in 0..<3 {
                    let layerOffset = CGFloat(layer) * 4
                    let amplitude: CGFloat = 6 + CGFloat(layer) * 3
                    let frequency = 3.0 + Double(layer) * 1.5
                    let speed = 2.0 + Double(layer) * 0.5
                    let layerOpacity = 0.5 - Double(layer) * 0.15

                    // Left wave
                    var leftPath = Path()
                    let leftX = centerX - artworkHalf - margin - layerOffset
                    let steps = 60
                    for step in 0...steps {
                        let t = CGFloat(step) / CGFloat(steps)
                        let y = centerY - artworkHalf + t * artworkSize
                        let wave = sin(Double(t) * frequency * .pi + time * speed) * Double(amplitude)
                        let point = CGPoint(x: leftX + CGFloat(wave), y: y)
                        if step == 0 { leftPath.move(to: point) }
                        else { leftPath.addLine(to: point) }
                    }
                    context.stroke(leftPath, with: .color(color.opacity(layerOpacity)), lineWidth: 2)

                    // Right wave
                    var rightPath = Path()
                    let rightX = centerX + artworkHalf + margin + layerOffset
                    for step in 0...steps {
                        let t = CGFloat(step) / CGFloat(steps)
                        let y = centerY - artworkHalf + t * artworkSize
                        let wave = sin(Double(t) * frequency * .pi + time * speed + .pi) * Double(amplitude)
                        let point = CGPoint(x: rightX + CGFloat(wave), y: y)
                        if step == 0 { rightPath.move(to: point) }
                        else { rightPath.addLine(to: point) }
                    }
                    context.stroke(rightPath, with: .color(color.opacity(layerOpacity)), lineWidth: 2)
                }
            }
            .blur(radius: 3)
        }
    }
}

// MARK: - Preview with all 3 styles

struct WaveformStylesMockup: View {
    let accentColor = Color(red: 0.3, green: 0.6, blue: 1.0)

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Waveform Styles")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                // Style 1
                VStack(spacing: 8) {
                    Text("1. Soft Glow Bars")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                    artworkWithWaveform {
                        GlowBarsWaveformView(color: accentColor, isAnimating: true)
                    }
                }

                // Style 2
                VStack(spacing: 8) {
                    Text("2. Concentric Ripple Rings")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                    artworkWithWaveform {
                        RippleRingsWaveformView(color: accentColor, isAnimating: true)
                    }
                }

                // Style 3
                VStack(spacing: 8) {
                    Text("3. Organic Sine Wave")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                    artworkWithWaveform {
                        SineWaveWaveformView(color: accentColor, isAnimating: true)
                    }
                }
            }
            .padding(.vertical, 30)
        }
        .background(Color(white: 0.1))
    }

    @ViewBuilder
    func artworkWithWaveform<W: View>(@ViewBuilder waveform: () -> W) -> some View {
        ZStack {
            waveform()

            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.teal.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .overlay(
                    Text("Cover Art")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                )
        }
        .frame(width: 300, height: 300)
    }
}

#Preview("Waveform Styles") {
    WaveformStylesMockup()
}
