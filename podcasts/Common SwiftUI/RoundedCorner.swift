import SwiftUI

/// Used as a fallback for iOS 15 when `UnevenRoundedRectangle` is necessary
struct PCUnevenRoundedRectangle: Shape {
    let topLeadingRadius: CGFloat
    let bottomLeadingRadius: CGFloat
    let bottomTrailingRadius: CGFloat
    let topTrailingRadius: CGFloat

    init(topLeadingRadius: CGFloat,
         bottomLeadingRadius: CGFloat,
         bottomTrailingRadius: CGFloat,
         topTrailingRadius: CGFloat) {
        self.topLeadingRadius = topLeadingRadius
        self.bottomLeadingRadius = bottomLeadingRadius
        self.bottomTrailingRadius = bottomTrailingRadius
        self.topTrailingRadius = topTrailingRadius
    }

    func path(in rect: CGRect) -> Path {
        let path = CGMutablePath()

        // Start at top-left corner
        path.move(to: CGPoint(x: rect.minX + topLeadingRadius, y: rect.minY))

        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
        if topTrailingRadius > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY + topTrailingRadius),
                        radius: topTrailingRadius,
                        startAngle: .pi * 3 / 2,
                        endAngle: 0,
                        clockwise: false)
        }

        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
        if bottomTrailingRadius > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - bottomTrailingRadius, y: rect.maxY - bottomTrailingRadius),
                        radius: bottomTrailingRadius,
                        startAngle: 0,
                        endAngle: .pi / 2,
                        clockwise: false)
        }

        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY))
        if bottomLeadingRadius > 0 {
            path.addArc(center: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY - bottomLeadingRadius),
                        radius: bottomLeadingRadius,
                        startAngle: .pi / 2,
                        endAngle: .pi,
                        clockwise: false)
        }

        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeadingRadius))
        if topLeadingRadius > 0 {
            path.addArc(center: CGPoint(x: rect.minX + topLeadingRadius, y: rect.minY + topLeadingRadius),
                        radius: topLeadingRadius,
                        startAngle: .pi,
                        endAngle: .pi * 3 / 2,
                        clockwise: false)
        }

        path.closeSubpath()

        return Path(path)
    }
}
