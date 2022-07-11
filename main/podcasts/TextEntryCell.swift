import UIKit

class TextEntryCell: ThemeableCell {
    @IBOutlet var borderView: ThemeableSelectionView! {
        didSet {
            borderView.isSelected = false
            borderView.layer.cornerRadius = 6
            borderView.layer.borderWidth = 2
        }
    }

    @IBOutlet var textField: ThemeableTextField!
    @IBOutlet var iconView: UIImageView! {
        didSet {
            iconView.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }
}
