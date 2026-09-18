import UIKit

class SearchInfoCell: ThemeableCell {
    @IBOutlet var infoImage: UIImageView!
    @IBOutlet var infoTitle: UILabel!
    @IBOutlet var infoSubtitle: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
