import UIKit

class ProfileIntroViewController: PCViewController, SyncSigninDelegate {
    weak var upgradeRootViewController: UIViewController?

    @IBOutlet var createAccountBtn: ThemeableRoundedButton! {
        didSet {
            createAccountBtn.setTitle(L10n.Localizable.createAccount, for: .normal)
            createAccountBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        }
    }
    
    @IBOutlet var signInBtn: ThemeableRoundedButton! {
        didSet {
            signInBtn.setTitle(L10n.Localizable.signIn, for: .normal)
            signInBtn.shouldFill = false
            signInBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        }
    }
    
    @IBOutlet var profileIllustration: UIImageView! {
        didSet {
            profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
        }
    }
    
    @IBOutlet var signOrCreateLabel: ThemeableLabel! {
        didSet {
            signOrCreateLabel.text = L10n.Localizable.signInPrompt
            signOrCreateLabel.style = .primaryText01
        }
    }
    
    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.text = L10n.Localizable.signInMessage
            infoLabel.style = .primaryText02
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Localizable.setupAccount
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        closeButton.accessibilityLabel = L10n.Localizable.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        
        handleThemeChanged()
        let doneButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        doneButton.accessibilityLabel = L10n.Localizable.accessibilityCloseDialog
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }
    
    override func handleThemeChanged() {
        profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
    }
    
    @objc private func doneTapped() {
        closeWindow()
    }
    
    private func closeWindow(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: completion)
        AnalyticsHelper.createAccountDismissed()
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }
    
    @IBAction func signInTapped() {
        let signinPage = SyncSigninViewController()
        signinPage.delegate = self
        
        navigationController?.pushViewController(signinPage, animated: true)

        AnalyticsHelper.createAccountSignIn()
    }
    
    @IBAction func createTapped() {
        let selectAccountVC = SelectAccountTypeViewController()
        navigationController?.pushViewController(selectAccountVC, animated: true)

        AnalyticsHelper.createAccountConfirmed()
    }
    
    // MARK: - Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
