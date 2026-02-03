import UIKit

class AddCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel! {
        didSet {
            cellLabel.font = UIFont.font(ofSize: 17.0, scalingWith: .body)
        }
    }

    @IBOutlet var cellSecondaryLabel: UILabel! {
        didSet {
            cellSecondaryLabel.font = UIFont.font(ofSize: 17.0, scalingWith: .body)
        }
    }

    @IBOutlet var cellButton: UIButton!

    func setImage(imageName: String, tintColor: UIColor? = nil) {
        cellImage.tintColor = tintColor
        cellImage.image = UIImage(named: imageName)
    }
}
