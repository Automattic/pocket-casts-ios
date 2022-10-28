import UIKit

class AddCell: ThemeableCell {
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var cellLabel: UILabel!
    @IBOutlet var cellSecondaryLabel: UILabel!
    @IBOutlet var cellButton: UIButton!

    func setImage(imageName: String, tintColor: UIColor? = nil) {
        cellImage.tintColor = tintColor
        cellImage.image = UIImage(named: imageName)
    }
}
