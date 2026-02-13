import PocketCastsDataModel
import UIKit

class PodcastFilterSelectionCell: ThemeableCell {
    @IBOutlet var podcastImage: UIImageView! {
        didSet {
            podcastImage.backgroundColor = ThemeColor.primaryUi01()
            podcastImage.layer.cornerRadius = 4
        }
    }

    @IBOutlet var shadowView: UIView! {
        didSet {
            shadowView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView.layer.shadowOpacity = 0.1
            shadowView.layer.shadowRadius = 2
            shadowView.layer.cornerRadius = 4

            shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.layer.bounds).cgPath
        }
    }

    @IBOutlet var podcastTitle: UILabel! {
        didSet {
            podcastTitle.font = UIFont.font(ofSize: 16, weight: .medium, scalingWith: .callout)
        }
    }

    @IBOutlet var podcastAuthor: ThemeableLabel! {
        didSet {
            podcastAuthor.style = .primaryText02
            podcastAuthor.font = UIFont.font(ofSize: 14, weight: .regular, scalingWith: .subheadline)
        }
    }

    private var podcast: Podcast!
    @IBOutlet var tickImageView: UIImageView!
    @IBOutlet var selectedImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        let tickImage = UIImage(named: "tick")
        tickImageView.image = tickImage
        tickImageView.tintColor = ThemeColor.primaryInteractive02()
        style = .primaryUi01
        updateSize()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        tickImageView?.isHidden = !selected
        selectedImageView.image = selected ? UIImage(named: "checkbox-selected") : UIImage(named: "checkbox-unselected")
    }

    func populateFrom(_ newPodcast: Podcast) {
        podcast = newPodcast

        podcastTitle.text = podcast.title
        podcastTitle.setLetterSpacing(-0.2)
        podcastAuthor.text = podcast.author
        podcastAuthor.setLetterSpacing(-0.2)

        ImageManager.sharedManager.loadImage(podcastUuid: podcast.uuid, imageView: podcastImage, size: .list, showPlaceHolder: true)
    }

    func setTintColor(color: UIColor) {
        selectedImageView.tintColor = color
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        ImageManager.sharedManager.cancelLoad(podcastImage)
        setSelected(false, animated: false)
    }

    override func handleThemeDidChange() {
        tickImageView.tintColor = ThemeColor.primaryInteractive02()
        podcastImage.backgroundColor = ThemeColor.primaryUi01()
    }

    // MARK : - Dynamic Type Updates

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateSize()
        }
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let iconSize = max(24, metric.scaledValue(for: 24))

        selectedImageView.updateSizeConstraints(to: iconSize)

        let imageSize = max(52, metric.scaledValue(for: 52))
        podcastImage?.updateSizeConstraints(to: imageSize)
    }
}
