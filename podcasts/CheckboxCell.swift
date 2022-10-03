
import UIKit

class CheckboxCell: ThemeableCell {
    @IBOutlet var selectButton: BouncyButton! {
        didSet {
            selectButton.onImage = UIImage(named: "checkbox-selected")
            selectButton.offImage = UIImage(named: "checkbox-unselected")
        }
    }

    @IBOutlet var episodeTitle: ThemeableLabel!

    var filterColor: UIColor? {
        didSet {
            updateButtonColor()
        }
    }

    private var tickImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        let tickImage = UIImage(named: "tick")
        tickImageView = UIImageView(frame: CGRect(x: 2, y: 2, width: 20, height: 20))
        tickImageView.image = tickImage
        tickImageView.tintColor = ThemeColor.primaryInteractive02()
        selectButton.imageView?.addSubview(tickImageView)
    }

    func setSelectedState(_ selected: Bool) {
        selectButton.currentlyOn = selected
        tickImageView?.isHidden = !selected
    }

    override func handleThemeDidChange() {
        tickImageView?.tintColor = ThemeColor.primaryInteractive02()
        updateButtonColor()
    }

    private func updateButtonColor() {
        guard let filterColor = filterColor else { return }

        selectButton.tintColor = ThemeColor.filterInteractive01(filterColor: filterColor)
    }
}
