#if !os(watchOS)
    import UIKit

    public extension UIView {
        func anchorToAllSidesOf(view: UIView?) {
            guard let view else { return }

            translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: view.leadingAnchor),
                trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomAnchor.constraint(equalTo: view.bottomAnchor),
                topAnchor.constraint(equalTo: view.topAnchor)
            ])
        }

        func anchorToAllSidesOf(view: UIView?, padding: CGFloat) {
            guard let view else { return }

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

        func removeAllSubviews() {
            for subview in subviews {
                subview.removeFromSuperview()
            }
        }

        func updateSizeConstraints(to value: CGFloat) {
            updateSizeConstraints(width: value, height: value)
        }

        func updateSizeConstraints(width: CGFloat, height: CGFloat) {
            for constraint in self.constraints {
                if constraint.secondItem != nil {
                    continue
                }
                switch constraint.firstAttribute {
                case .width:
                    constraint.constant = width
                case .height:
                    constraint.constant = height
                default:
                    continue
                }
            }
        }
    }
#endif
