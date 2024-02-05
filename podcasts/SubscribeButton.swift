import UIKit

protocol SubscribeButtonDelegate: AnyObject {
    func subscribeButtonTapped()
}

class SubscribeButton: ThemeableView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var backgroundView: ThemeableView!
    @IBOutlet var tickImageView: TintableImageView! {
        didSet {
            tickImageView.image = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.primaryInteractive02())
        }
    }

    @IBOutlet var titleLabel: ThemeableLabel! {
        didSet {
            titleLabel.text = L10n.subscribe
            titleLabel.style = .primaryInteractive02
        }
    }

    weak var delegate: SubscribeButtonDelegate?
    var onSubscribe: (() -> Void)?
    var isSelected = false
    var isHighlighted = false
    var isEnabled = true {
        didSet {
            isUserInteractionEnabled = isEnabled
            alpha = isEnabled ? 1 : 0.25
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("SubscribeButton", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.borderWidth = 2
        setBackgroundColors()
    }

    func setBackgroundColors() {
        contentView.backgroundColor = ThemeColor.primaryUi02()
        if isHighlighted || isSelected {
            titleLabel.style = .primaryInteractive02
            backgroundView.layer.borderColor = ThemeColor.support02().cgColor
            backgroundView.layer.backgroundColor = ThemeColor.support02().cgColor
            tickImageView.image = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.primaryInteractive02())
            titleLabel.isHidden = isSelected
            tickImageView.isHidden = false
            tickImageView.alpha = isSelected ? 1 : 0
        } else {
            titleLabel.style = .primaryInteractive01
            backgroundView.layer.borderColor = ThemeColor.primaryInteractive01().cgColor
            backgroundView.layer.backgroundColor = ThemeColor.primaryUi02().cgColor
            tickImageView.isHidden = true
            titleLabel.isHidden = false
            tickImageView.alpha = 0
        }
    }

    override func handleThemeDidChange() {
        setBackgroundColors()
    }
}
