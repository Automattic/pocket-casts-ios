import UIKit

class CheckboxSubtitleCell: ThemeableCell {
    private var tickImageView: UIImageView!
    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var subtitleLabel: ThemeableLabel! {
        didSet {
            subtitleLabel.style = .primaryText02
        }
    }

    @IBOutlet var selectButton: BouncyButton! {
        didSet {
            selectButton.onImage = UIImage(named: "checkbox-selected")
            selectButton.offImage = UIImage(named: "checkbox-unselected")
            selectButton.tintColor = ThemeColor.primaryInteractive01()
        }
    }

    func setSelectedState(_ selected: Bool) {
        selectButton.currentlyOn = selected
        tickImageView?.isHidden = !selected
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let tickImage = UIImage(named: "tick")
        tickImageView = UIImageView(frame: CGRect(x: 2, y: 2, width: 20, height: 20))
        tickImageView.image = tickImage
        tickImageView.tintColor = ThemeColor.primaryInteractive02()
        selectButton.imageView?.addSubview(tickImageView)
    }

    override func handleThemeDidChange() {
        selectButton.tintColor = ThemeColor.primaryInteractive01()
        tickImageView?.tintColor = ThemeColor.primaryInteractive02()
    }
}
