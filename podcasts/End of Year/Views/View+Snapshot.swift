import SwiftUI

extension View {
    /// Returns a `UIImage` from a SwiftUI View
    @MainActor
    public func snapshot() -> UIImage {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: self)
            renderer.scale = 3
            guard let renderedImage = renderer.uiImage else {
                assert(false, "Rendered ImageRenderer image shouldn't be `nil`")
                return UIImage()
            }
            return renderedImage
        } else {
            let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.top))
            let view = controller.view

            let targetSize = controller.view.intrinsicContentSize
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear

            let renderer = UIGraphicsImageRenderer(size: targetSize)

            return renderer.image { _ in
                view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
    }
}
