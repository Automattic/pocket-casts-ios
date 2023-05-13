import UIKit

class TimeStepperCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel!
    @IBOutlet var cellSecondaryLabel: ThemeableLabel! {
        didSet {
            cellSecondaryLabel.style = .primaryText02
        }
    }

    @IBOutlet var timeStepper: CustomTimeStepper!

    @IBOutlet var cellTextToImageConstraint: NSLayoutConstraint!

    var onValueChanged: ((TimeInterval) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        cellTextToImageConstraint.isActive = false

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
        cellImage.tintColor = tintColor
        cellImage.image = UIImage(named: imageName)
    }

    func configureAccessibilityLabel(text: String, time: String) {
        let accessibilityLabel = "\(text), \(time)"
        self.accessibilityLabel = accessibilityLabel
    }

    @objc private func stepperChanged(_ sender: CustomTimeStepper) {
        onValueChanged?(sender.currentValue)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
