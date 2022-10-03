import PocketCastsServer
import UIKit

protocol AccountUpdatedDelegate: AnyObject {
    func accountUpdatedAcknowledged()
}

class AccountUpdatedViewController: UIViewController {
    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var detailLabel: ThemeableLabel! {
        didSet {
            detailLabel.style = .primaryText02
        }
    }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var newsletterView: ThemeableView!

    @IBOutlet var newsletterSwitch: ThemeableSwitch! {
        didSet {
            newsletterSwitch.setOn(false, animated: false)
        }
    }

    @IBOutlet var newsletterImage: UIImageView! {
        didSet {
            newsletterImage.tintColor = ThemeColor.primaryField03Active()
        }
    }

    @IBOutlet var newsletterHeadingLabel: ThemeableLabel! {
        didSet {
            newsletterHeadingLabel.text = L10n.pocketCastsNewsletter
        }
    }

    @IBOutlet var newsletterDetailLabel: ThemeableLabel! {
        didSet {
            newsletterDetailLabel.style = .primaryText02
            newsletterDetailLabel.text = L10n.pocketCastsNewsletterDescription
        }
    }

    @IBOutlet var doneBtn: ThemeableRoundedButton! {
        didSet {
            doneBtn.setTitle(L10n.done.localizedCapitalized, for: .normal)
        }
    }

    var titleText: String?
    var detailText: String?
    var imageName: (() -> String)?
    var hideNewsletter = true
    weak var delegate: AccountUpdatedDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""

        titleLabel.text = titleText
        detailLabel.text = detailText
        if let imageNameFunc = imageName {
            imageView.image = UIImage(named: imageNameFunc())
        }
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped(_:)))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        newsletterView.isHidden = hideNewsletter

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)

        Analytics.track(.accountUpdatedShown)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    @IBAction func closeTapped(_ sender: Any) {
        if let delegate = delegate {
            delegate.accountUpdatedAcknowledged()
            return
        }
        dismiss(animated: true, completion: nil)
        Analytics.track(.accountUpdatedDismissed)
    }

    @objc private func themeDidChange() {
        if let imageNameFunc = imageName {
            imageView.image = UIImage(named: imageNameFunc())
        }
    }

    @IBAction func newsletterOptInChanged(_ sender: UISwitch) {
        Analytics.track(.newsletterOptInChanged, properties: ["enabled": sender.isOn, "source": "account_updated"])

        ServerSettings.setMarketingOptIn(sender.isOn)
    }
}
