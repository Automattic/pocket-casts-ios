import PocketCastsServer
import SafariServices
import UIKit

class CancelInfoViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet var cancelLabel: ThemeableLabel! {
        didSet {
            cancelLabel.style = .primaryText02
        }
    }

    @IBOutlet var platformLabel: ThemeableLabel!
    @IBOutlet var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = 71.5
            profileImageView.image = UIImage(named: AppTheme.cancelSubscriptionImageName())
        }
    }

    @IBOutlet var showMeButton: ThemeableRoundedButton! {
        didSet {
            showMeButton.shouldFill = false
            showMeButton.layer.cornerRadius = 12
        }
    }

    @IBOutlet var doneButton: ThemeableRoundedButton! {
        didSet {
            doneButton.layer.cornerRadius = 12
        }
    }

    private var safariViewController: SFSafariViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.cancelSubscription

        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped(_:)))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)

        configureLabels()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    @objc func themeDidChange() {
        profileImageView.image = UIImage(named: AppTheme.cancelSubscriptionImageName())
    }

    override func viewDidLayoutSubviews() {
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
    }

    private func configureLabels() {
        let subscriptionPlatform = SubscriptionHelper.subscriptionPlatform()

        switch subscriptionPlatform {
        case .iOS:
            platformLabel.text = L10n.plusSubscriptionApple
            cancelLabel.text = L10n.plusSubscriptionAppleDetails
        case .android:
            platformLabel.text = L10n.plusSubscriptionGoogle
            cancelLabel.text = L10n.plusSubscriptionGoogleDetails
        case .web:
            platformLabel.text = L10n.plusSubscriptionWeb
            cancelLabel.text = L10n.plusSubscriptionWebDetails
        default:
            platformLabel.text = ""
            cancelLabel.text = ""
        }
    }

    @IBAction func showMeTapped(_ sender: Any) {
        if let url = URL(string: ServerConstants.Urls.cancelSubscription) {
            safariViewController = SFSafariViewController(with: url)
            safariViewController?.delegate = self
            if let vc = safariViewController {
                present(vc, animated: true)
            }
        }
    }

    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        safariViewController?.delegate = nil
        safariViewController = nil
    }
}
