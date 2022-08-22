import UIKit

class SearchInfoCell: ThemeableCell {
    @IBOutlet var infoImage: UIImageView!
    @IBOutlet var infoTitle: UILabel!
    @IBOutlet var infoSubtitle: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    
    func showFailed() {
        infoTitle.text = L10n.Localizable.discoverSearchFailed
        infoSubtitle.text = L10n.Localizable.discoverSearchFailedMsg
        infoImage.image = UIImage(named: "discover_nointernet")
    }
    
    func showNoResults() {
        infoTitle.text = L10n.Localizable.discoverNoPodcastsFound
        infoSubtitle.text = L10n.Localizable.discoverNoPodcastsFoundMsg
        infoImage.image = UIImage(named: "discover_noresult")
    }
}
