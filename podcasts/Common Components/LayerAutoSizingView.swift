import UIKit

class LayerAutoSizingView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.sublayers?.first?.frame = bounds
    }
}
