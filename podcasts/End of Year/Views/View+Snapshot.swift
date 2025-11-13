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

    @MainActor
    func snapshotUIKit(origin: CGPoint = .zero, size: CGSize = .zero) -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = size == .zero ? controller.view.intrinsicContentSize : size
        view?.backgroundColor = .clear
        view?.bounds = CGRect(origin: origin, size: targetSize)

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
