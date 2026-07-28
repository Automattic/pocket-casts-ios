import SwiftUI
import PocketCastsUtils

/// Shows circular progress view that can count up (CountDirection.up) or count down (CountDirection.down)
public struct CircularProgressView<S: ShapeStyle>: View {
    let value: Double
    let stroke: S
    let strokeWidth: Double
    var direction: CountDirection = .up

    private var from: Double {
        switch direction {
        case .down:
            return 1 - value
        case .up:
            return 0
        }
    }

    private var to: Double {
        switch direction {
        case .down:
            return 1
        case .up:
            return value
        }
    }

    public var body: some View {
        Circle()
            .trim(from: from.clamped(to: 0..<1), to: to.clamped(to: 0..<1))
            .stroke(
                stroke,
                style: .init(lineWidth: strokeWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }

    public enum CountDirection {
        case up, down
    }

    public init(value: Double, stroke: S, strokeWidth: Double, direction: CountDirection = .up) {
        self.value = value
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.direction = direction
    }
}
