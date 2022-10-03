import UIKit

class PodcastChooserCell: ThemeableCell {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var podcastName: UILabel!

    @IBOutlet var podcastSelectBg: UIImageView!
    @IBOutlet var podcastSelectTick: UIImageView!

    override func handleThemeDidChange() {
        podcastSelectBg.tintColor = ThemeColor.primaryInteractive01()
        podcastSelectTick.tintColor = ThemeColor.primaryInteractive02()
    }

    func setIsSelected(_ selected: Bool) {
        podcastSelectTick.isHidden = !selected
        podcastSelectBg.image = selected ? UIImage(named: "checkbox-selected") : UIImage(named: "checkbox-unselected")
    }
}
