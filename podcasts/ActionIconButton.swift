import UIKit

class ActionIconButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        centerTitleLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centerTitleLabel()
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        invalidateIntrinsicContentSize()
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.titleRect(forContentRect: contentRect)
        let height: CGFloat
        if let text = title(for: .normal) {
            let size = (text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
            let lines = size.width / contentRect.width
            height = ceil(lines) * size.height
        } else {
            height = rect.height
        }
        let imageSize: CGFloat = imageView?.image?.size.height ?? 24
        return CGRect(x: 0, y: imageSize + 10, width: contentRect.width, height: height)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.imageRect(forContentRect: contentRect)
        return CGRect(x: contentRect.width / 2.0 - rect.width / 2.0, y: 0, width: rect.width, height: rect.height)
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        if imageView?.image != nil {
            let labelRect = titleRect(forContentRect: contentRect(forBounds: bounds))
            return CGSize(width: size.width, height: labelRect.maxY)
        }

        return size
    }

    private func centerTitleLabel() {
        titleLabel?.textAlignment = .center
    }
}
