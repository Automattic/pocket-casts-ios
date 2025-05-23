import SwiftUI

struct PositionModifier: ViewModifier {
    var xOffset: CGFloat
    var yOffset: CGFloat
    var size: CGSize
    var frame: CGRect
    var corner: UnitPoint

    func body(content: Content) -> some View {
        let (xPosition, yPosition) = calculatePositions()

        content
            .position(x: xPosition, y: yPosition)
    }

    private func calculatePositions() -> (CGFloat, CGFloat) {
        let xPosition: CGFloat
        let yPosition: CGFloat

        let midX = size.width / 2
        let midY = size.height / 2

        switch corner {
        case .topLeading:
            xPosition = midX + xOffset
            yPosition = midY + yOffset
        case .topTrailing:
            xPosition = frame.width - midX + xOffset
            yPosition = midY + yOffset
        case .bottomLeading:
            xPosition = midX + xOffset
            yPosition = frame.height - midY + yOffset
        case .bottomTrailing:
            xPosition = frame.width - midX + xOffset
            yPosition = frame.height - midY + yOffset
        default:
            // Default to center if no specific corner
            xPosition = midX + xOffset
            yPosition = midY + yOffset
        }

        return (xPosition, yPosition)
    }
}

extension View {
    func position(x: CGFloat, y: CGFloat, for size: CGSize, in frame: CGRect, corner: UnitPoint = .center) -> some View {
        self.modifier(PositionModifier(xOffset: x, yOffset: y, size: size, frame: frame, corner: corner))
    }
}
