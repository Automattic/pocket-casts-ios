import UIKit

class ActionIconButton: UIButton {
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let imageView, let frame = calculatedImageFrame {
            imageView.frame = frame
        }

        if let titleLabel, let frame = calculatedTitleFrame {
            titleLabel.textAlignment = .center
            titleLabel.frame = frame
        }
    }

    private var calculatedTitleFrame: CGRect? {
        guard let rect = titleLabel?.frame else { return nil }

        let contentRect = bounds

        let height: CGFloat
        if let text = title(for: .normal) {
            let size = (text as NSString).size(withAttributes: [.font: UIFont.font(ofSize: 13, scalingWith: .footnote)])
            let lines = size.width / contentRect.width
            height = ceil(lines) * size.height
        } else {
            height = rect.height
        }
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize: CGFloat = imageView?.image?.size.height ?? 24
        let scaledHeight = metrics.scaledValue(for: imageSize)
        return CGRect(x: 0, y: scaledHeight + 10, width: contentRect.width, height: height)
    }

    private var calculatedImageFrame: CGRect? {
        guard let baseSize = imageView?.image?.size else { return nil }
        let contentRect = bounds
        let metrics = UIFontMetrics(forTextStyle: .largeTitle)
        let scaledWidth = metrics.scaledValue(for: baseSize.width)
        let scaledHeight = metrics.scaledValue(for: baseSize.height)
        return CGRect(x: contentRect.width / 2.0 - scaledWidth / 2.0, y: 0, width: scaledWidth, height: scaledHeight)
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        if imageView?.image != nil {
            return CGSize(width: size.width, height: calculatedTitleFrame?.maxY ?? 0)
        }

        return size
    }
}
