import UIKit

class PodcastChooserCell: ThemeableCell {
    @IBOutlet var podcastImage: PodcastImageView!

    @IBOutlet var podcastName: UILabel! {
        didSet {
            podcastName.font = UIFont.font(ofSize: 16, weight: .regular, scalingWith: .body)
        }
    }

    @IBOutlet var podcastSelectBg: UIImageView!
    @IBOutlet var podcastSelectTick: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSize()
    }

    override func handleThemeDidChange() {
        podcastSelectBg.tintColor = ThemeColor.primaryInteractive01()
        podcastSelectTick.tintColor = ThemeColor.primaryInteractive02()
    }

    func setIsSelected(_ selected: Bool) {
        podcastSelectTick.isHidden = !selected
        podcastSelectBg.image = selected ? UIImage(named: "checkbox-selected") : UIImage(named: "checkbox-unselected")
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let size = max(metric.scaledValue(for: 56), 56)
        podcastImage.updateSizeConstraints(to: size)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }
}
