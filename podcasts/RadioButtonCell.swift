import UIKit

class RadioButtonCell: ThemeableCell {
    @IBOutlet var selectButton: BouncyButton! {
        didSet {
            selectButton.onImage = UIImage(named: "checkcircle-unselected")?.withRenderingMode(.alwaysTemplate)
            selectButton.offImage = UIImage(named: "checkcircle-unselected")?.withRenderingMode(.alwaysTemplate)
            selectButton.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var title: ThemeableLabel! {
        didSet {
            title.font = UIFont.font(ofSize: 16, weight: .medium, scalingWith: .callout)
            title.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var roundView: UIView! {
        didSet {
            roundView.layer.cornerRadius = roundView.bounds.width / 2
        }
    }

    func setSelectState(_ selected: Bool) {
        selectButton.currentlyOn = selected
        roundView.isHidden = !selected
    }

    func setTintColor(color: UIColor) {
        selectButton.tintColor = color
        roundView.backgroundColor = color
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: RadioButtonCell, _) in
            view.updateSize()
        }
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let iconSize = max(24, metric.scaledValue(for: 24))

        selectButton.updateSizeConstraints(to: iconSize)
    }
}
