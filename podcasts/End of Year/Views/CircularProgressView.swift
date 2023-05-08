import SwiftUI

/// Shows circular progress view that can count up (CountDirection.up) or count down (CountDirection.down)
struct CircularProgressView<S: ShapeStyle>: View {
    let value: Double
    let stroke: S
    let strokeWidth: Double
    var direction: CountDirection = .up

    private var from: Double {
        switch direction {
        case .up:
            return 1 - value
        case .down:
            return 0
        }
    }

    private var to: Double {
        switch direction {
        case .up:
            return 1
        case .down:
            return value
        }
    }

    var body: some View {
        Circle()
            .trim(from: from.clamped(to: 0..<1), to: to.clamped(to: 0..<1))
            .stroke(
                stroke,
                style: .init(lineWidth: strokeWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }

    enum CountDirection {
        case up, down
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContent()
    }

    struct PreviewContent: View {
        @State var progress: Double = 0.5
        @State var stroke: Double = 10
        var body: some View {
            VStack {
                HStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Counting up")

                        CircularProgressView(value: progress, stroke: Color.primary, strokeWidth: stroke)
                    }

                    VStack(spacing: 10) {
                        Text("Counting down")

                        CircularProgressView(value: progress, stroke: Color.primary, strokeWidth: stroke, direction: .down)
                    }
                }

                HStack {
                    Text("Progress")
                    Slider(value: $progress, in: 0...1)
                }

                HStack {
                    Text("Stroke Width")
                    Slider(value: $stroke, in: 1...30)
                }

                Spacer()
            }.padding()
        }
    }
}
