
import UIKit

class AccountActionCell: ThemeableCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSize()
    }
    
    var imageAndTextColor: UIColor? = nil {
        didSet {
            handleThemeDidChange()
        }
    }

    @IBOutlet var cellLabel: ThemeableLabel! {
        didSet {
            cellLabel.style = iconStyle
            cellLabel.font = UIFont.font(ofSize: 15.0, scalingWith: .callout)
        }
    }

    @IBOutlet var cellImage: UIImageView! {
        didSet {
            cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
        }
    }

    override var iconStyle: ThemeStyle {
        didSet {
            handleThemeDidChange()
        }
    }

    @IBOutlet var counterLabel: ThemeableLabel! {
        didSet {
            counterLabel.style = .primaryInteractive02
            counterLabel.font = UIFont.font(ofSize: 15, weight: .medium, scalingWith: .callout)
        }
    }

    @IBOutlet var counterView: ThemeableView! {
        didSet {
            counterView.style = .primaryIcon01
            counterView.layer.cornerRadius = 16
        }
    }

    override func handleThemeDidChange() {
        guard let imageAndTextColor else {
            cellImage.tintColor = AppTheme.colorForStyle(iconStyle)
            cellLabel.style = iconStyle
            return
        }

        cellImage.tintColor = imageAndTextColor
        cellLabel.textColor = imageAndTextColor
    }

    private var disclosureImageView: TintableImageView?

    var showsDisclosureIndicator = false {
        didSet {
            if showsDisclosureIndicator {
                let imageView = TintableImageView(image: UIImage(named: "chevron"))
                disclosureImageView = imageView
                accessoryView = imageView
                updateColor()
                updateDisclosureScale()
            } else {
                disclosureImageView = nil
                accessoryView = nil
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageAndTextColor = nil

        updateSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    func updateSize() {
        updateImageScale()
        updateDisclosureScale()
    }

    func updateImageScale() {
        let fontMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let size = max(24, fontMetric.scaledValue(for: 24))
        cellImage.updateSizeConstraints(to: size)
    }

    private func updateDisclosureScale() {
        let fontMetric = UIFontMetrics(forTextStyle: .largeTitle)
        let size = max(24, fontMetric.scaledValue(for: 24))
        disclosureImageView?.updateSizeConstraints(to: size)
    }

}
