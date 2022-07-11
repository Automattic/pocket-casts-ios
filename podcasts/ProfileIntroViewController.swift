import UIKit

class ProfileIntroViewController: PCViewController, SyncSigninDelegate {
    @IBOutlet var createAccountBtn: ThemeableRoundedButton! {
        didSet {
            createAccountBtn.setTitle(L10n.createAccount, for: .normal)
            createAccountBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        }
    }
    
    @IBOutlet var signInBtn: ThemeableRoundedButton! {
        didSet {
            signInBtn.setTitle(L10n.signIn, for: .normal)
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
            signOrCreateLabel.text = L10n.signInPrompt
            signOrCreateLabel.style = .primaryText01
        }
    }
    
    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.text = L10n.signInMessage
            infoLabel.style = .primaryText02
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.setupAccount
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        
        handleThemeChanged()
        let doneButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        doneButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }
    
    override func handleThemeChanged() {
        profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
    }
    
    @objc private func doneTapped() {
        closeWindow()
    }
    
    private func closeWindow() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - SyncSigninDelegate
    
    func signingProcessCompleted() {
        closeWindow()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }
    
    @IBAction func signInTapped() {
        let signinPage = SyncSigninViewController()
        signinPage.delegate = self
        
        navigationController?.pushViewController(signinPage, animated: true)
    }
    
    @IBAction func createTapped() {
        let selectAccountVC = SelectAccountTypeViewController()
        navigationController?.pushViewController(selectAccountVC, animated: true)
    }
    
    // MARK: - Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
