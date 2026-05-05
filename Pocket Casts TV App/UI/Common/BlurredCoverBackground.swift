import SwiftUI

struct BlurredCoverBackground: ViewModifier {
    let imageName: String?
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size * 1.5, height: size * 1.5)
                        .blur(radius: 100)
                        .opacity(0.75)
                        .offset(x: -(size * 0.5), y: -(size * 0.5))
                        .allowsHitTesting(false)
                }
            }
    }
}

extension View {
    func blurredCoverBackground(_ imageName: String?, size: CGFloat) -> some View {
        modifier(BlurredCoverBackground(imageName: imageName, size: size))
    }
}
