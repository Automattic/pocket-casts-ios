import PocketCastsServer
import UIKit

class SinglePodcastViewController: UIViewController, DiscoverSummaryProtocol {
    @IBOutlet var podcastImage: PodcastImageView!

    @IBOutlet var podcastTitle: ThemeableLabel!
    @IBOutlet var podcastDescription: ThemeableLabel! {
        didSet {
            podcastDescription.style = .primaryText02
        }
    }

    @IBOutlet var typeBadgeLabel: ThemeableLabel! {
        didSet {
            typeBadgeLabel.layer.cornerRadius = 4
        }
    }

    @IBOutlet var subscribeButton: BouncyButton! {
        didSet {
            subscribeButton.tintColor = ThemeColor.primaryIcon02()
            subscribeButton.onImage = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.support02())
            subscribeButton.offImage = UIImage(named: "discover_add")?.tintedImage(ThemeColor.primaryIcon02())

            subscribeButton.offAccessibilityLabel = L10n.subscribe
            subscribeButton.onAccessibilityLabel = L10n.subscribed
        }
    }

    @IBOutlet var titleToDescriptionConstraint: NSLayoutConstraint!
    private weak var delegate: DiscoverDelegate?
    private var podcast: DiscoverPodcast?
    private var item: DiscoverItem?
    private var featuredDescription: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? ThemeableView)?.style = .primaryUi02

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showPodcast))
        view.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        view.translatesAutoresizingMaskIntoConstraints = false

        populate()
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        populate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let listId = item?.uuid else { return }

        AnalyticsHelper.listImpression(listId: listId)
    }

    // MARK: DiscoverSummaryProtocol

    func populateFrom(item: DiscoverItem) {
        guard let source = item.source else { return }

        self.item = item
        DiscoverServerHandler.shared.discoverPodcastList(source: source, completion: { [weak self] podcastList in
            guard let discoverPodcast = podcastList?.podcasts else { return }

            self?.podcast = discoverPodcast.first
            self?.featuredDescription = podcastList?.description
            DispatchQueue.main.async {
                self?.populate()
            }
        })
    }

    // MARK: Populate UI

    func populate() {
        guard let podcast = podcast else { return }

        if let title = podcast.title?.localized {
            podcastTitle?.text = title
            let maxTitleChars = podcastTitle.bounds.width * 0.11
            let fontSize: CGFloat = title.count > Int(maxTitleChars) ? 15 : 18
            podcastTitle.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.bold)
            titleToDescriptionConstraint.constant = fontSize == 15 ? 4 : 6
        }
        if let description = featuredDescription {
            podcastDescription.text = description
        }
        if let uuid = podcast.uuid {
            podcastImage?.setPodcast(uuid: uuid, size: .grid)
        }
        if let isSponsored = item?.isSponsored, isSponsored {
            typeBadgeLabel.text = L10n.discoverSponsored
            typeBadgeLabel.style = .primaryText02
            podcastDescription.numberOfLines = 3
        } else {
            typeBadgeLabel.text = L10n.discoverFreshPick
            typeBadgeLabel.style = .support02
        }

        let fontSize: CGFloat = UIScreen.main.bounds.width >= 360 ? 15 : 14
        podcastDescription.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.regular)

        podcastTitle.sizeToFit()
        podcastDescription.sizeToFit()

        subscribeButton.shouldAnimate = false
        subscribeButton.currentlyOn = delegate?.isSubscribed(podcast: podcast) ?? false
        subscribeButton.shouldAnimate = true

        view.sizeToFit()
    }

    // MARK: Actions

    @IBAction func subscribeTapped(_ sender: Any) {
        guard !subscribeButton.currentlyOn, let podcast = podcast else { return }

        subscribeButton.currentlyOn = true

        if let listId = item?.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
        }

        delegate?.subscribe(podcast: podcast)
    }

    @objc func showPodcast() {
        guard let podcast = podcast else { return }

        delegate?.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: true, listUuid: item?.uuid)

        if let listId = item?.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid)
        }
    }

    // MARK: / Notifications

    @objc func themeDidChange() {
        subscribeButton.tintColor = ThemeColor.primaryIcon02()
        subscribeButton.onImage = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.support02())
        subscribeButton.offImage = UIImage(named: "discover_add")?.tintedImage(ThemeColor.primaryIcon02())

        updateTypeBadgeColors()
    }

    private func updateTypeBadgeColors() {
        if let isSponsored = item?.isSponsored, isSponsored {
            typeBadgeLabel.style = .secondaryText02
        } else {
            typeBadgeLabel.style = .support02
        }
    }
}
