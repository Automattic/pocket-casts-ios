
import UIKit

class RoundedLabel: ThemeableLabel {
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 10.0
    @IBInspectable var rightInset: CGFloat = 10.0

    var backgroundStyle: ThemeStyle = .contrast04 {
        didSet {
            updateBgColor()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
        updateBgColor()
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        setNeedsLayout()
        return super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let parentSize = super.intrinsicContentSize
        return CGSize(width: parentSize.width + leftInset + rightInset, height: parentSize.height + topInset + bottomInset)
    }

    override func handleThemeDidChange() {
        updateBgColor()
    }

    private func updateBgColor() {
        backgroundColor = AppTheme.colorForStyle(backgroundStyle)
    }
}
