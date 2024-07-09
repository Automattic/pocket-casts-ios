import SwiftUI

struct AudioWaveformView: View {
    let baseLineWidth: CGFloat = 2
    let baseLineSpacing: CGFloat = 2
    var scale: CGFloat
    var width: CGFloat

    enum LineHeight: Int, CaseIterable {
        case shortest = 0
        case medium = 1
        case tallest = 2

        var fraction: CGFloat {
            switch self {
            case .shortest: return 0.1
            case .medium: return 0.25
            case .tallest: return 0.5
            }
        }

        var fadeStartScale: CGFloat {
            switch self {
            case .shortest: return 1.8
            case .medium: return 0.5
            case .tallest: return 0.5
            }
        }

        var fadeDuration: CGFloat {
            return 0.5  // This determines how quickly each line type fades out
        }
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let lineCount = Int(width / (lineWidth + lineSpacing))
                let midY = size.height / 2

                for index in 0..<lineCount {
                    let x = CGFloat(index) * (lineWidth + lineSpacing)
                    let lineHeight = getLineHeight(for: index)
                    let barHeight = size.height * lineHeight.fraction
                    let opacity = opacityForLine(at: index)

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: midY - barHeight / 2))
                    path.addLine(to: CGPoint(x: x, y: midY + barHeight / 2))

                    context.opacity = opacity
                    context.stroke(path, with: .color(.gray), lineWidth: lineWidth)
                }
            }
            .frame(width: width)
        }
    }

    private var lineWidth: CGFloat {
        baseLineWidth
    }

    private var lineSpacing: CGFloat {
        baseLineSpacing * scale
    }

    private var lineCount: Int {
        Int(width / (lineWidth + lineSpacing))
    }

    private func opacityForLine(at index: Int) -> Double {
        let lineHeight = getLineHeight(for: index)

        let fadeStartScale = lineHeight.fadeStartScale
        let fadeEndScale = fadeStartScale + lineHeight.fadeDuration

        if scale >= fadeEndScale {
            return 1.0
        } else if scale <= fadeStartScale {
            return 0.0
        } else {
            return Double((scale - fadeStartScale) / lineHeight.fadeDuration)
        }
    }

    private func getLineHeight(for index: Int) -> LineHeight {
        switch index % 16 {
        case 0:
            return .tallest
        case 4, 8, 12:
            return .medium
        default:
            return .shortest
        }
    }

    private func lineBar(for index: Int, viewHeight: CGFloat) -> some View {
        let lineHeight = getLineHeight(for: index)
        let barHeight = viewHeight * lineHeight.fraction

        return VStack {
            Spacer()
            Rectangle()
                .fill(Color.gray)
                .frame(width: lineWidth, height: barHeight)
            Spacer()
        }
    }
}
