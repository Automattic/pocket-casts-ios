import PocketCastsServer
import UIKit

class CategoryCell: ThemeableCell {
    @IBOutlet var categoryName: UILabel!
    @IBOutlet var categoryImage: UIImageView!

    func populateFrom(_ category: DiscoverCategory) {
        if let name = category.name?.localized {
            categoryName.accessibilityLabel = name
            categoryName.text = name
        }

        if let imageUrl = category.icon {
            categoryImage.kf.setImage(with: URL(string: imageUrl), placeholder: nil, options: nil, progressBlock: nil) { result in
                switch result {
                case .success:
                    self.categoryImage.image = self.categoryImage?.image?.withRenderingMode(.alwaysTemplate)
                    self.categoryImage.tintColor = ThemeColor.primaryIcon02()
                default:
                    break // don't really care
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        setSelected(false, animated: false)
        categoryImage.image = nil
        categoryName.text = ""
    }

    override func handleThemeDidChange() {
        categoryImage.tintColor = ThemeColor.primaryIcon02()
    }
}
