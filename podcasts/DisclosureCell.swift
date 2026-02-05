import UIKit

class DisclosureCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel! {
        didSet {
            cellLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
        }
    }
    @IBOutlet var disclosureImage: UIImageView!
    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
            cellSecondaryLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
        }
    }

    @IBOutlet var cellTextToImageConstraint: NSLayoutConstraint!

    private let baseDisclosureSize: CGFloat = 32

    override func awakeFromNib() {
        super.awakeFromNib()

        cellTextToImageConstraint.isActive = false
        updateSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .body)
        let disclosureSize = max(baseDisclosureSize, metric.scaledValue(for: baseDisclosureSize))
        updateSizeConstraints(of: disclosureImage, to: disclosureSize)
    }

    func setImage(imageName: String?, tintColor: UIColor? = nil) {
        if let imageName = imageName {
            cellTextToImageConstraint.isActive = true
            cellImage.tintColor = tintColor
            cellImage.image = UIImage(named: imageName)
        } else {
            cellTextToImageConstraint.isActive = false
            cellImage.image = nil
        }
    }

    override func handleThemeDidChange() {
        disclosureImage.tintColor = ThemeColor.primaryIcon02()
    }

    var isLocked = true {
        didSet {
            contentView.isUserInteractionEnabled = isLocked
            contentView.alpha = isLocked ? 1 : 0.3
        }
    }
}
