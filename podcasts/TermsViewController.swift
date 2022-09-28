import UIKit

class TermsViewController: PCViewController {
    @IBOutlet var noButton: ThemeableRoundedButton! {
        didSet {
            noButton.shouldFill = false
            noButton.layer.borderWidth = 2
            noButton.layer.cornerRadius = 12
        }
    }

    @IBOutlet var clipboardImageView: ThemeableImageView! {
        didSet {
            clipboardImageView.imageNameFunc = AppTheme.termsOfUseImageName
        }
    }

    @IBOutlet var shadowView: TopShadowView!
    @IBOutlet var titleLabel: ThemeableLabel!

    @IBOutlet var detail1Label: ThemeableLabel! {
        didSet {
            detail1Label.style = .primaryText02
        }
    }

    @IBOutlet var detail2Label: ThemeableLabel! {
        didSet {
            detail2Label.style = .primaryText02
        }
    }

    @IBOutlet var termsButton: ThemeableRoundedButton! {
        didSet {
            termsButton.buttonStyle = .primaryUi01
            termsButton.textStyle = .primaryInteractive01
        }
    }

    @IBOutlet var privacyButton: ThemeableRoundedButton! {
        didSet {
            privacyButton.buttonStyle = .primaryUi01
            privacyButton.textStyle = .primaryInteractive01
        }
    }

    var newSubscription: NewSubscription

    init(newSubscription: NewSubscription) {
        self.newSubscription = newSubscription
        super.init(nibName: "TermsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.termsOfUse

        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped(_:)))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        Analytics.track(.termsOfUseShown)
    }

    @IBAction func agreeTapped(_ sender: Any) {
        let paymentVc = SelectPaymentFreqViewController(newSubscription: newSubscription)
        navigationController?.pushViewController(paymentVc, animated: true)
        Analytics.track(.termsOfUseAccepted)
    }

    @IBAction func noTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        Analytics.track(.termsOfUseRejected)
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        Analytics.track(.termsOfUseDismissed)
    }

    @IBAction func showTermsOfUse(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showTermsOfUsePageKey, data: nil)
    }

    @IBAction func showPrivacyPolicy(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPrivacyPolicyPageKey, data: nil)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }
}
