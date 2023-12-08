
import UIKit

class PromotionFinishedViewController: UIViewController {
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
            avatarImageView.imageNameFunc = AppTheme.plusCancelledGoldImageName
        }
    }

    @IBOutlet var thanksLabel: ThemeableLabel! {
        didSet {
            thanksLabel.style = .primaryText02
        }
    }

    @IBOutlet var upgradeButton: ThemeableRoundedButton! {
        didSet {
            upgradeButton.shouldFill = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.trialFinished
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "profile-nothanksclose"), style: .done, target: self, action: #selector(doneTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }

    @IBAction func doneTapped(_ sender: Any) {
        Settings.setPromotionFinishedAcknowledged(true)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func upgradeTapped(_ sender: Any) {
        dismiss(animated: true) {
            guard let controller = SceneHelper.rootViewController() else { return }
            NavigationManager.sharedManager.showUpsellView(from: controller, source: .promotionFinished)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
