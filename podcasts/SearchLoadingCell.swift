import UIKit

class SearchLoadingCell: ThemeableCell {
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!

    override func prepareForReuse() {
        super.prepareForReuse()

        loadingIndicator.stopAnimating()
    }
}
