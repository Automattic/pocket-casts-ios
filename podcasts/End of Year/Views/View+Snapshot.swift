import SwiftUI

extension View {
    /// Returns a `UIImage` from a SwiftUI View
    @MainActor
    public func snapshot(scale: CGFloat = 2) -> UIImage {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: self)
            renderer.scale = scale
            guard let renderedImage = renderer.uiImage else {
                assertionFailure("Rendered ImageRenderer image shouldn't be `nil`")
                return UIImage()
            }
            return renderedImage
        } else {
            let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.top))
            let view = controller.view

            let targetSize = controller.view.intrinsicContentSize
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear

            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

            return renderer.image { _ in
                view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
    }
}
