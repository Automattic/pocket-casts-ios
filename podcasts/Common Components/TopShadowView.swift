import UIKit

class TopShadowView: ThemeableView {
    var hideShadow = false {
        didSet {
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        if hideShadow {
            layer.shadowRadius = 0
        } else {
            layer.masksToBounds = false
            layer.shadowColor = UIColor.black.cgColor // TODO: fix for theme
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowOpacity = 0.15
            layer.shadowRadius = 2
        }
    }
}
