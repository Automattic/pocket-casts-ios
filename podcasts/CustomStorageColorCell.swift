import UIKit

class CustomStorageColorCell: UICollectionViewCell {
    @IBOutlet var colorView: UIView! {
        didSet {
            colorView.layer.cornerRadius = 20
        }
    }

    @IBOutlet var selectedView: ThemeableView! {
        didSet {
            selectedView.layer.cornerRadius = 6
            selectedView.isHidden = true
            selectedView.style = .primaryInteractive02
        }
    }

    @IBOutlet var imageView: UIImageView! {
        didSet {
            imageView.layer.cornerRadius = 20
            imageView.clipsToBounds = true
        }
    }

    func setBackgroundColor(color: UIColor) {
        colorView.backgroundColor = color
    }

    override var isSelected: Bool {
        didSet {
            selectedView.isHidden = !isSelected
        }
    }

    override func prepareForReuse() {
        selectedView.isHidden = true
    }
}
