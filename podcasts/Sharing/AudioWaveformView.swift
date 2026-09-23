import SwiftUI

struct AudioWaveformView: View {
    let width: CGFloat

    private let baseLineWidth: CGFloat = 2
    private let baseLineSpacing: CGFloat = 6

    enum LineHeight: CaseIterable {
        case shortest
        case medium
        case tallest

        /// The height of the line as a fraction of the full height of the view
        var fraction: CGFloat {
            switch self {
            case .shortest: return 0.1
            case .medium: return 0.25
            case .tallest: return 0.5
            }
        }
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let lineCount = Int(width / (lineWidth + lineSpacing))
                let midY = size.height / 2

                for index in 0..<lineCount {
                    let x = CGFloat(index) * (lineWidth + lineSpacing)
                    let lineHeight = getLineHeight(for: index)
                    let barHeight = size.height * lineHeight.fraction

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: midY - barHeight / 2))
                    path.addLine(to: CGPoint(x: x, y: midY + barHeight / 2))

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
        baseLineSpacing
    }

    private func getLineHeight(for index: Int) -> LineHeight {
        switch index % 20 {
        case 0:
            return .tallest
        case 5, 10, 15:
            return .medium
        default:
            return .shortest
        }
    }
}
