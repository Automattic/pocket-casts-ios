import UIKit
import PocketCastsUtils
import PocketCastsServer

class ProfileIntroViewController: PCViewController, SyncSigninDelegate {
    weak var upgradeRootViewController: UIViewController?

    private var buttonFont: UIFont {
        .font(ofSize: 18, weight: .semibold, scalingWith: .body, maxSizeCategory: .extraExtraLarge)
    }

    @IBOutlet var errorLabel: ThemeableLabel! {
        didSet {
            errorLabel.style = .support05
            errorLabel.font = .font(with: .subheadline, maxSizeCategory: .extraExtraLarge)
            hideError()
        }
    }

    @IBOutlet var createAccountBtn: ThemeableRoundedButton! {
        didSet {
            createAccountBtn.setTitle(L10n.createAccount, for: .normal)
            createAccountBtn.titleLabel?.font = buttonFont
        }
    }

    @IBOutlet var authenticationProviders: UIStackView!
    @IBOutlet var signInBtn: ThemeableRoundedButton! {
        didSet {
            signInBtn.isHidden = FeatureFlag.signInWithApple.enabled
            signInBtn.setTitle(L10n.signIn, for: .normal)
            signInBtn.shouldFill = false
            signInBtn.titleLabel?.font = buttonFont
        }
    }

    @IBOutlet var passwordAuthOption: ThemeableUIButton! {
        didSet {
            passwordAuthOption.isHidden = !FeatureFlag.signInWithApple.enabled
            passwordAuthOption.setTitle(L10n.accountLogin, for: .normal)
            passwordAuthOption.titleLabel?.font = buttonFont
        }
    }

    @IBOutlet var profileIllustration: UIImageView! {
        didSet {
            profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
        }
    }

    @IBOutlet var signOrCreateLabel: ThemeableLabel! {
        didSet {
            signOrCreateLabel.text = L10n.signInPrompt
            signOrCreateLabel.style = .primaryText01
            signOrCreateLabel.font = .font(with: .title2, weight: .bold, maxSizeCategory: .accessibilityMedium)
        }
    }

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.text = infoLabelText ?? L10n.signInMessage
            infoLabel.style = .primaryText02
            infoLabel.font = .font(ofSize: 18, weight: .medium, scalingWith: .body, maxSizeCategory: .accessibilityMedium)
        }
    }

    var infoLabelText: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.setupAccount
        showPocketCastsLogoInTitle()

        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton

        handleThemeChanged()
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        Analytics.track(.setupAccountShown)
    }

    override func handleThemeChanged() {
        profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
    }

    @objc private func doneTapped() {
        closeWindow()
    }

    @IBAction func signInTapped() {
        hideError()

        let signinPage = SyncSigninViewController()
        signinPage.delegate = self

        navigationController?.pushViewController(signinPage, animated: true)

        AnalyticsHelper.createAccountSignIn()
        Analytics.track(.setupAccountButtonTapped, properties: ["button": "sign_in"])
    }

    @IBAction func createTapped() {
        let selectAccountVC = SelectAccountTypeViewController()
        navigationController?.pushViewController(selectAccountVC, animated: true)

        AnalyticsHelper.createAccountConfirmed()

        Analytics.track(.setupAccountButtonTapped, properties: ["button": "create_account"])
    }

    // MARK: - View Configuration
    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }

    // MARK: - SyncSigninDelegate
    func signingProcessCompleted() {
        closeWindow {
            if let presentingController = self.upgradeRootViewController {
                let newSubscription = NewSubscription(isNewAccount: false, iap_identifier: "")
                presentingController.present(SJUIUtils.popupNavController(for: TermsViewController(newSubscription: newSubscription)), animated: true)
            }
        }
    }
}

private extension ProfileIntroViewController {
    func closeWindow(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: completion)
        AnalyticsHelper.createAccountDismissed()
        Analytics.track(.setupAccountDismissed)
    }

    func showPocketCastsLogoInTitle() {
        let imageView = ThemeableImageView(frame: .zero)
        imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalImageName
        imageView.accessibilityLabel = title

        navigationItem.titleView = imageView
    }

    func hideError() {
        errorLabel.alpha = 0
        errorLabel.text = nil
    }

    func showError(_ error: Error? = nil) {
        if let error {
            FileLog.shared.addMessage("Failed to connect SSO account: \(error.localizedDescription)")
        }

        errorLabel.text = L10n.accountSsoFailed
        errorLabel.alpha = 1
    }
}
