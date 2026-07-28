import UIKit

class TimeStepperCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel! {
        didSet {
            cellLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
            cellLabel.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
            cellSecondaryLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
            cellSecondaryLabel.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var timeStepper: CustomTimeStepper!

    @IBOutlet var cellTextToImageConstraint: NSLayoutConstraint!
    @IBOutlet var cellTextToMarginConstraint: NSLayoutConstraint!

    var onValueChanged: ((TimeInterval) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: TimeStepperCell, _) in
            view.updateSize()
        }

        cellTextToImageConstraint.isActive = false
        cellTextToMarginConstraint.isActive = true

        timeStepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        onValueChanged = nil
    }

    deinit {
        timeStepper.removeTarget(nil, action: nil, for: .valueChanged)
    }

    func configureWithImage(imageName: String, tintColor: UIColor) {
        cellTextToImageConstraint.isActive = true
        cellTextToMarginConstraint.isActive = false
        cellImage.tintColor = tintColor
        cellImage.image = UIImage(named: imageName)
        updateSize()
    }

    func configureAccessibilityLabel(text: String, time: Int) {
        let localizedTimeInterval = TimeInterval(time).localizedTimeDescription ?? ""
        let accessibilityLabel = "\(text), \(localizedTimeInterval)"
        self.accessibilityLabel = accessibilityLabel
    }

    @objc private func stepperChanged(_ sender: CustomTimeStepper) {
        onValueChanged?(sender.currentValue)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let settingsSize = max(24, metric.scaledValue(for: 24))
        cellImage.updateSizeConstraints(to: settingsSize)
    }
}
