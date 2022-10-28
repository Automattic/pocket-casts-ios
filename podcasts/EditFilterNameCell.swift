import UIKit

class EditFilterNameCell: ThemeableCell {
    @IBOutlet var nameTextField: ThemeableTextField! {
        didSet {
            // nameTextField.alternateBgColor = true
        }
    }

    @IBOutlet var nameLabel: ThemeableLabel! {
        didSet {
            nameLabel.text = L10n.name.localizedCapitalized
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
