import UIKit

class EditFilterNameCell: ThemeableCell {
    @IBOutlet var nameTextField: ThemeableTextField! {
        didSet {
            // nameTextField.alternateBgColor = true
        }
    }
    
    @IBOutlet var nameLabel: ThemeableLabel! {
        didSet {
            nameLabel.text = L10n.Localizable.name.localizedCapitalized
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
