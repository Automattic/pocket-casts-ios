import UIKit

class RadioButtonCell: ThemeableCell {
    @IBOutlet var selectButton: BouncyButton! {
        didSet {
            selectButton.onImage = UIImage(named: "checkcircle-unselected")?.withRenderingMode(.alwaysTemplate)
            selectButton.offImage = UIImage(named: "checkcircle-unselected")?.withRenderingMode(.alwaysTemplate)
            selectButton.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var title: ThemeableLabel!
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
}
