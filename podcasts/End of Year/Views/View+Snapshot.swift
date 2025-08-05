import SwiftUI

extension View {
    /// Returns a `UIImage` from a SwiftUI View
    @MainActor
    public func snapshot(scale: CGFloat = 2) -> UIImage {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        guard let renderedImage = renderer.uiImage else {
            assertionFailure("Rendered ImageRenderer image shouldn't be `nil`")
            return UIImage()
        }
        return renderedImage
    }
}
