import PocketCastsServer
import UIKit

protocol CollectionHeaderLinkDelegate: AnyObject {
    func linkTapped()
}

class DiscoverCollectionHeader: UICollectionReusableView {
    @IBOutlet var collageImageView: UIImageView! {
        didSet {
            collageImageView.alpha = 0.1
        }
    }

    @IBOutlet var collageTintView: UIView! {
        didSet {
            collageTintView.alpha = 0.2
        }
    }

    @IBOutlet var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = 40
        }
    }

    @IBOutlet var avatarBorderView: ThemeableView! {
        didSet {
            avatarBorderView.layer.cornerRadius = 44
        }
    }

    @IBOutlet var avatarShadowView: UIView! {
        didSet {
            avatarShadowView.layer.cornerRadius = 40
            avatarShadowView.layer.shadowColor = UIColor.black.cgColor
            avatarShadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
            avatarShadowView.layer.shadowOpacity = 0.15
            avatarShadowView.layer.shadowRadius = 4
            avatarShadowView.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 80, height: 80)).cgPath
        }
    }

    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var headerView: ThemeableView! {
        didSet {
            headerView.style = .primaryUi02
        }
    }

    @IBOutlet var linkView: ThemeableView! {
        didSet {
            linkView.style = .primaryUi06
            linkView.layer.cornerRadius = 8

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(linkTapped))
            linkView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var linkImageView: ThemeableImageView! {
        didSet {
            linkImageView.imageStyle = .primaryIcon02
        }
    }

    @IBOutlet var linkArrowImageView: ThemeableImageView! {
        didSet {
            linkArrowImageView.imageStyle = .primaryIcon02
        }
    }

    @IBOutlet var linkLabel: ThemeableLabel! {
        didSet {
            linkLabel.style = .primaryText02
        }
    }

    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
        }
    }

    private var podcastCollection: PodcastCollection?
    weak var linkDelegate: CollectionHeaderLinkDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func populate(podcastCollection: PodcastCollection?) {
        guard let podcastCollection = podcastCollection else {
            headerView.isHidden = true
            return
        }
        self.podcastCollection = podcastCollection
        headerView.isHidden = false
        if let title = podcastCollection.title?.localized {
            titleLabel.text = title
        }
        if let description = podcastCollection.description {
            descriptionLabel.text = description
        }
        if let subtitle = podcastCollection.subtitle?.localized {
            subtitleLabel.text = subtitle.localizedUppercase
        }
        if let avatarUrl = podcastCollection.collectionImage {
            avatarBorderView.isHidden = false
            ImageManager.sharedManager.loadDiscoverImage(imageUrl: avatarUrl, imageView: avatarImageView, placeholderSize: .grid)
        } else {
            avatarBorderView.isHidden = true
        }
        setupCollageImage()

        if let linkTitle = podcastCollection.webTitle, podcastCollection.webUrl != nil {
            linkView.isHidden = false
            linkLabel.text = linkTitle
        } else {
            linkView.isHidden = true
        }
        setSubtitleColor()
    }

    private func setSubtitleColor() {
        if let colors = podcastCollection?.colors, let darkColor = colors.onDarkBackground, let lightColor = colors.onLightBackground {
            let subtitleColor = Theme.isDarkTheme() ? darkColor : lightColor
            subtitleLabel.textColor = UIColor(hex: subtitleColor)
        } else {
            subtitleLabel.textColor = AppTheme.colorForStyle(.support05)
        }
    }

    private func setupCollageImage() {
        guard let mobileCollage = podcastCollection?.collageImages?.filter({ $0.key == "mobile" }), let collageUrl = mobileCollage.first?.image_url else { return }

        ImageManager.sharedManager.retrieveDiscoverImage(imageUrl: collageUrl, completionHandler: { image in
            guard let currentCGImage = image?.cgImage else {
                return
            }
            let currentCIImage = CIImage(cgImage: currentCGImage)

            let filter = CIFilter(name: "CIColorMonochrome")
            filter?.setValue(currentCIImage, forKey: "inputImage")

            // set a gray value for the tint color
            filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: "inputColor")

            filter?.setValue(1.0, forKey: "inputIntensity")
            guard let outputImage = filter?.outputImage else { return }

            let context = CIContext()

            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                let processedImage = UIImage(cgImage: cgimg)
                self.collageImageView.image = processedImage
            }
        })
        setImageTint()
    }

    private func setImageTint() {
        if let darkTintColor = podcastCollection?.colors?.onDarkBackground, let lightTintColor = podcastCollection?.colors?.onLightBackground {
            let backgroundColor = Theme.isDarkTheme() ? darkTintColor : lightTintColor
            collageTintView.backgroundColor = UIColor(hex: backgroundColor)
        } else {
            collageTintView.backgroundColor = AppTheme.colorForStyle(.support09)
        }
    }

    @objc private func linkTapped() {
        linkDelegate?.linkTapped()
    }

    @objc func themeDidChange() {
        setImageTint()
        setSubtitleColor()
    }
}
