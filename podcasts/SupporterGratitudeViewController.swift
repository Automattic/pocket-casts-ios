import PocketCastsDataModel
import PocketCastsServer
import UIKit

class SupporterGratitudeViewController: PCViewController, SyncSigninDelegate {
    var podcastInfo: PodcastInfo?
    var bundleUuid: String?
    @IBOutlet var podcastArtwork: BundleImageView!
    @IBOutlet var heartView: PodcastHeartView!
    @IBOutlet var detailsLabel: ThemeableLabel! {
        didSet {
            detailsLabel.style = .primaryText02
        }
    }

    init(podcastInfo: PodcastInfo) {
        self.podcastInfo = podcastInfo
        super.init(nibName: "SupporterGratitudeViewController", bundle: nil)
    }

    init(bundleUuid: String) {
        self.bundleUuid = bundleUuid
        super.init(nibName: "SupporterGratitudeViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.signIn

        (view as? ThemeableView)?.style = .primaryUi01
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        podcastArtwork.transform = CGAffineTransform(rotationAngle: CGFloat(-14).degreesToRadians)
        heartView.transform = CGAffineTransform(rotationAngle: CGFloat(14).degreesToRadians)

        if let podcastTitle = podcastInfo?.title {
            setInfoWithName(podcastTitle)
        }
        if let uuid = podcastInfo?.uuid {
            podcastArtwork.setPodcast(uuid: uuid, size: .grid)
            heartView.setDefaultGreen()
            updatePodcastHeartColors(uuid: uuid)
        }
        if let bundleUuid = bundleUuid {
            loadBundleCollection(uuid: bundleUuid)
            heartView.setDefaultGreen()
        }
    }

    @IBAction func signInTapped() {
        let signinPage = SyncSigninViewController()
        signinPage.delegate = self

        navigationController?.pushViewController(signinPage, animated: true)
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - SyncSigninDelegate

    func signingProcessCompleted() {
        dismiss(animated: true, completion: {
            var uuid: String? = self.bundleUuid
            if self.bundleUuid == nil, let podcastUuid = self.podcastInfo?.uuid, let containerBundle = SubscriptionHelper.bundleSubscriptionForPodcast(podcastUuid: podcastUuid) {
                uuid = containerBundle.bundleUuid
            }
            NavigationManager.sharedManager.navigateTo(NavigationManager.supporterBundlePageKey, data: [NavigationManager.supporterBundleUuid: uuid as Any])
        })
    }

    private func updatePodcastHeartColors(uuid: String) {
        CacheServerHandler.shared.loadPodcastColors(podcastUuid: uuid, allowCachedVersion: false, completion: { _, lightThemeTint, darkThemeTint in
            guard let lightThemeTint = lightThemeTint, let darkThemeTint = darkThemeTint else { return }
            DispatchQueue.main.sync { () in
                self.heartView.setGradientColors(light: UIColor(hex: lightThemeTint), dark: UIColor(hex: darkThemeTint))
            }
        })
    }

    private func loadBundleCollection(uuid: String) {
        let bundleUrl = ServerHelper.bundleUrl(bundleUuid: uuid)
        DiscoverServerHandler.shared.discoverPodcastCollection(source: bundleUrl.absoluteString, completion: { podcastCollection in
            guard let podcastCollection = podcastCollection else { return }

            DispatchQueue.main.async {
                if let bundleTitle = podcastCollection.author {
                    self.setInfoWithName(bundleTitle)
                }
                if let collageUrl = podcastCollection.collectionImage {
                    self.podcastArtwork.setBundleImageUrl(url: collageUrl, size: .grid)
                }
                if let colors = podcastCollection.colors, let darkColor = colors.onDarkBackground, let lightColor = colors.onLightBackground {
                    self.heartView.setGradientColors(light: UIColor(hex: lightColor), dark: UIColor(hex: darkColor))
                }
            }
        })
    }

    private func setInfoWithName(_ name: String) {
        detailsLabel.text = L10n.paidPodcastSupporterSigninPrompt(name)
    }
}
