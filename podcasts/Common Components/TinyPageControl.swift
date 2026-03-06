import UIKit

protocol TinyPageControlDelegate: AnyObject {
    func pageDidChange(_ newPage: Int)
}

class TinyPageControl: UIControl {
    var numberOfPages = 1 {
        didSet {
            setNeedsDisplay()
            updateAccessibilityLabel()
        }
    }

    var currentPage = 0 {
        didSet {
            setNeedsDisplay()
            updateAccessibilityLabel()
        }
    }

    var allowPagesToLoop = true
    weak var delegate: TinyPageControlDelegate?

    var dotDiameter = 5 as CGFloat
    var dotSpacing = 6 as CGFloat

    private var onColor = ThemeColor.primaryUi05Selected()
    private var offColor = ThemeColor.primaryUi05()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraits.button
        NotificationCenter.default.addObserver(self, selector: #selector(updateForTheme), name: Constants.Notifications.themeChanged, object: nil)
        updateForTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func updateForTheme() {
        onColor = ThemeColor.primaryUi05Selected()
        offColor = ThemeColor.primaryUi05()
        backgroundColor = UIColor.clear
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            let proposedNextPage = currentPage + 1
            if proposedNextPage < numberOfPages {
                currentPage += 1
            } else {
                if allowPagesToLoop {
                    currentPage = 0
                } else {
                    return
                }
            }

            if let delegate = delegate {
                delegate.pageDidChange(currentPage)
            }
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()
        context.setAllowsAntialiasing(true)

        let currentBounds = bounds
        let dotsWidth = CGFloat(numberOfPages) * dotDiameter + CGFloat(max(0, numberOfPages - 1)) * dotSpacing
        var x = currentBounds.midX - dotsWidth / 2
        let y = currentBounds.midY - dotDiameter / 2

        for i in 0 ..< numberOfPages {
            let dotRect = CGRect(x: x, y: y, width: dotDiameter, height: dotDiameter)

            if i == currentPage {
                context.setFillColor(onColor.cgColor)
                context.fillEllipse(in: dotRect.insetBy(dx: -0.5, dy: -0.5))
            } else {
                context.setFillColor(offColor.cgColor)
                context.fillEllipse(in: dotRect.insetBy(dx: -0.5, dy: -0.5))
            }

            x += dotDiameter + dotSpacing
        }

        // restore the context
        context.restoreGState()
    }

    private func updateAccessibilityLabel() {
        accessibilityLabel = L10n.pageControlPageProgressFormat((currentPage + 1).localized(), numberOfPages.localized())
    }
}
