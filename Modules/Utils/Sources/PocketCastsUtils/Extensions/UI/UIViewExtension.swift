#if !os(watchOS)
    import UIKit

    public extension UIView {
        func anchorToAllSidesOf(view: UIView?) {
            guard let view = view else { return }

            translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: view.leadingAnchor),
                trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomAnchor.constraint(equalTo: view.bottomAnchor),
                topAnchor.constraint(equalTo: view.topAnchor)
            ])
        }

        func anchorToAllSidesOf(view: UIView?, padding: CGFloat) {
            guard let view = view else { return }

            translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
                topAnchor.constraint(equalTo: view.topAnchor, constant: padding)
            ])
        }

        func sj_snapshot(afterScreenUpdate: Bool = false, opaque: Bool = true) -> UIImageView {
            let snapshot = sj_snapshotImage(afterScreenUpdate: afterScreenUpdate, opaque: opaque)

            return UIImageView(image: snapshot)
        }

        func sj_snapshotImage(afterScreenUpdate: Bool = false, opaque: Bool = true) -> UIImage? {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        }

        func moveTo(x: CGFloat, y: CGFloat) {
            if frame.origin.x == x, frame.origin.y == y { return }

            frame = CGRect(x: x, y: y, width: frame.width, height: frame.height)
        }

        func moveTo(x: CGFloat) {
            if frame.origin.x == x { return }

            frame = CGRect(x: x, y: frame.origin.y, width: frame.width, height: frame.height)
        }

        func moveTo(y: CGFloat) {
            if frame.origin.y == y { return }

            frame = CGRect(x: frame.origin.x, y: y, width: frame.width, height: frame.height)
        }

        func removeAllSubviews() {
            for subview in subviews {
                subview.removeFromSuperview()
            }
        }
    }
#endif
