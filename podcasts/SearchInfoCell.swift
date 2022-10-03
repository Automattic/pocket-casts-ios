import UIKit

class SearchInfoCell: ThemeableCell {
    @IBOutlet var infoImage: UIImageView!
    @IBOutlet var infoTitle: UILabel!
    @IBOutlet var infoSubtitle: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    func showFailed() {
        infoTitle.text = L10n.discoverSearchFailed
        infoSubtitle.text = L10n.discoverSearchFailedMsg
        infoImage.image = UIImage(named: "discover_nointernet")
    }

    func showNoResults() {
        infoTitle.text = L10n.discoverNoPodcastsFound
        infoSubtitle.text = L10n.discoverNoPodcastsFoundMsg
        infoImage.image = UIImage(named: "discover_noresult")
    }
}
