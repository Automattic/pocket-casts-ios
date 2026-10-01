
import UIKit
@IBDesignable
class RoundedBorderView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 4 {
        didSet {
            setupBorder()
        }
    }

    var getBorderColor: (() -> UIColor) = { AppTheme.tableDividerColor() } {
        didSet {
            setupBorder()
        }
    }

    var getBgColor: (() -> UIColor) = { UIColor.clear } {
        didSet {
            setupBorder()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupBorder()
        registerForTraitChanges([UITraitDisplayScale.self]) { (view: RoundedBorderView, _) in
            view.layer.borderWidth = view.hairlineWidth
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupBorder()
        registerForTraitChanges([UITraitDisplayScale.self]) { (view: RoundedBorderView, _) in
            view.layer.borderWidth = view.hairlineWidth
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupBorder() {
        clipsToBounds = true

        updateColors()
        layer.borderWidth = hairlineWidth
        layer.cornerRadius = cornerRadius

        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc private func themeChanged() {
        updateColors()
    }

    private func updateColors() {
        layer.borderColor = getBorderColor().cgColor
        backgroundColor = getBgColor()
    }
}
