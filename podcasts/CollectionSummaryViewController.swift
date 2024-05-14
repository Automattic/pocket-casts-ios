import PocketCastsServer
import UIKit

class CollectionSummaryViewController: UIViewController, DiscoverSummaryProtocol {
    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
        }
    }

    @IBOutlet var collageImageView: UIImageView! {
        didSet {
            collageImageView.layer.cornerRadius = 8
        }
    }

    @IBOutlet var collageShadowView: UIView! {
        didSet {
            collageShadowView.layer.cornerRadius = 8
            collageShadowView.layer.shadowColor = UIColor.black.cgColor
            collageShadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
            collageShadowView.layer.shadowOpacity = 0.15
            collageShadowView.layer.shadowRadius = 4
        }
    }

    @IBOutlet var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.cornerRadius = 40
        }
    }

    @IBOutlet var avatarBorderView: ThemeableView! {
        didSet {
            avatarBorderView.style = .primaryUi02
            avatarBorderView.layer.cornerRadius = 44
        }
    }

    @IBOutlet var avatarShadowView: UIView! {
        didSet {
            avatarShadowView.layer.cornerRadius = 40
            avatarShadowView.layer.shadowColor = UIColor.black.cgColor
            avatarShadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
            avatarShadowView.layer.shadowOpacity = 0.15
            avatarShadowView.layer.shadowRadius = 8
            avatarShadowView.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 80, height: 80)).cgPath
        }
    }

    private weak var delegate: DiscoverDelegate?
    private var item: DiscoverItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCollection))
        view.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChanged), name: Constants.Notifications.themeChanged, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let listId = item?.uuid {
            AnalyticsHelper.listImpression(listId: listId)
        }
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    // MARK: DiscoverSummaryProtocol

    var podcastCollection: PodcastCollection?
    func populateFrom(item: DiscoverItem, region: String?) {
        guard let source = item.source else { return }

        self.item = item
        DiscoverServerHandler.shared.discoverPodcastCollection(source: source, completion: { [weak self] podcastCollection in
            self?.podcastCollection = podcastCollection
            guard podcastCollection?.podcasts != nil || podcastCollection?.episodes != nil else { return }

            DispatchQueue.main.async {
                self?.populate()
            }
        })
    }

    // MARK: Populate UI

    private func hideAvatarView(_ isHidden: Bool) {
        avatarImageView.isHidden = isHidden
        avatarShadowView.isHidden = isHidden
        avatarBorderView.isHidden = isHidden
    }

    func populate() {
        if let title = podcastCollection?.title?.localized {
            titleLabel.text = title
        }
        if let description = podcastCollection?.description {
            descriptionLabel.text = description
        }
        if let subtitle = podcastCollection?.subtitle?.localized {
            subtitleLabel.text = subtitle.localizedUppercase
        }
        if let avatarUrl = podcastCollection?.collectionImage {
            hideAvatarView(false)
            ImageManager.sharedManager.loadDiscoverImage(imageUrl: avatarUrl, imageView: avatarImageView, placeholderSize: .list)
        } else {
            hideAvatarView(true)
        }
        if let mobileCollage = podcastCollection?.collageImages?.filter({ $0.key == "mobile" }), let collageUrl = mobileCollage.first?.image_url {
            ImageManager.sharedManager.loadDiscoverImage(imageUrl: collageUrl, imageView: collageImageView, placeholderSize: .grid)
        }
        setSubtitleColor()

        view.sizeToFit()
    }

    // MARK: Actions

    @objc func showCollection() {
        guard let delegate = delegate, let item = item else { return }

        if let podcasts = podcastCollection?.podcasts, !podcasts.isEmpty {
            delegate.showExpanded(item: item, podcasts: podcasts, podcastCollection: podcastCollection)
        } else if let episodes = podcastCollection?.episodes, !episodes.isEmpty {
            delegate.showExpanded(item: item, episodes: episodes, podcastCollection: podcastCollection)
        }
    }

    // MARK: Theme Change

    @objc func handleThemeChanged() {
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
}
