#if !os(watchOS)
import UIKit

/// A custom UITextField that allows a label appearing near the clear button
public class CustomTextField: UITextField {

    private let commonSpacing: CGFloat = 8

    public let rightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    private func setupLabel() {
        addSubview(rightLabel)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let clearButtonWidth: CGFloat = clearButtonRect(forBounds: bounds).width
        let rightInset: CGFloat = isEditing && text?.isEmpty == false ? clearButtonWidth + commonSpacing : commonSpacing
        rightLabel.sizeToFit()
        let labelWidth: CGFloat = rightLabel.frame.width

        let xPosition = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? rightInset : bounds.width - labelWidth - rightInset

        rightLabel.frame = CGRect(
            x: xPosition,
            y: (bounds.height - rightLabel.intrinsicContentSize.height) / 2,
            width: labelWidth,
            height: rightLabel.intrinsicContentSize.height
        )
    }

    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        return adjustRect(forBounds: bounds)
    }

    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return adjustRect(forBounds: bounds)
    }

    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return adjustRect(forBounds: bounds)
    }

    private func adjustRect(forBounds bounds: CGRect) -> CGRect {
        let labelWidth: CGFloat = rightLabel.frame.width
        let clearButtonWidth: CGFloat = clearButtonRect(forBounds: bounds).width
        let rightInset: CGFloat = isEditing && text?.isEmpty == false ? clearButtonWidth : 0
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return bounds.inset(by: UIEdgeInsets(top: 0, left: labelWidth + rightInset + (commonSpacing * 2), bottom: 0, right: commonSpacing))
        } else {
            return bounds.inset(by: UIEdgeInsets(top: 0, left: commonSpacing, bottom: 0, right: labelWidth + rightInset + (commonSpacing * 2)))
        }
    }

    @objc private func editingChanged() {
        setNeedsLayout()
    }
}
#endif
