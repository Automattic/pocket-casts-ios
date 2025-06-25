import UIKit

class HeadingCell: ThemeableCell {
    @IBOutlet var heading: UILabel!
    @IBOutlet var button: UIButton!

    var action: (() -> Void)?

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    @IBAction func buttonTapped(_ sender: UIButton) {
        action?()
    }
}
