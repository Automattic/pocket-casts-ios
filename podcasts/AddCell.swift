import UIKit

class AddCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel! {
        didSet {
            cellLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
        }
    }

    @IBOutlet var cellSecondaryLabel: UILabel! {
        didSet {
            cellSecondaryLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
        }
    }

    @IBOutlet var cellButton: UIButton!

    func setImage(imageName: String, tintColor: UIColor? = nil) {
        cellImage.tintColor = tintColor
        cellImage.image = UIImage(named: imageName)
    }
}
