import PocketCastsServer
import PocketCastsUtils
import UIKit

class CancelledAcknowledgeViewController: UIViewController {
    @IBOutlet var expiryLabel: ThemeableLabel!
    @IBOutlet var borderView: ThemeableSelectionView! {
        didSet {
            borderView.isSelected = false
            borderView.layer.borderWidth = 2
            borderView.layer.cornerRadius = 6
            borderView.unselectedStyle = .primaryUi05
        }
    }

    @IBOutlet var avatarImageView: ThemeableImageView! {
        didSet {
            avatarImageView.imageNameFunc = AppTheme.plusCancelledImageName
        }
    }

    @IBOutlet var thanksLabel: ThemeableLabel! {
        didSet {
            thanksLabel.style = .primaryText02
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.subscriptionCancelled
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "profile-nothanksclose"), style: .done, target: self, action: #selector(doneTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        let expiryString = DateFormatHelper.sharedHelper.longLocalizedFormat(SubscriptionHelper.subscriptionRenewalDate())
        expiryLabel.text = L10n.subscriptionCancelledMsg(expiryString)
    }

    @IBAction func doneTapped(_ sender: Any) {
        Settings.setSubscriptionCancelledAcknowledged(true)
        dismiss(animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
