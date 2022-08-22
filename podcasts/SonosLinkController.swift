import PocketCastsServer
import PocketCastsUtils
import UIKit

class SonosLinkController: PCViewController, SyncSigninDelegate {
    private let accountBtnTag = 1
    private let signinBtnTag = 2
    
    @IBOutlet var sonosImage: UIImageView! {
        didSet {
            sonosImage.image = Theme.isDarkTheme() ? UIImage(named: "sonos-dark") : UIImage(named: "sonos-light")
        }
    }
    
    @IBOutlet var connectBtn: ShiftyRoundButton! {
        didSet {
            connectBtn.buttonTapped = { [weak self] in
                if SyncManager.isUserLoggedIn() {
                    self?.connectWithSonos()
                }
                else {
                    self?.signIntoPocketCasts(signInMode: true)
                }
            }
        }
    }
    
    @IBOutlet var createBtn: ShiftyRoundButton! {
        didSet {
            createBtn.buttonTitle = L10n.Localizable.createAccount
            createBtn.buttonTapped = { [weak self] in
                self?.signIntoPocketCasts(signInMode: false)
            }
        }
    }
    
    @IBOutlet var mainMessage: UILabel!
    
    var callbackUri = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Localizable.sonosConnectPrompt
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(SonosLinkController.cancelTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if SyncManager.isUserLoggedIn() {
            mainMessage.text = L10n.Localizable.sonosConnectionPrivacyNotice
            connectBtn.buttonTitle = L10n.Localizable.sonosConnectAction
            createBtn.isHidden = true
        }
        else {
            mainMessage.text = L10n.Localizable.sonosConnectionSignInPrompt
            connectBtn.buttonTitle = L10n.Localizable.signIn.localizedUppercase
            createBtn.isHidden = false
        }
    }
    
    func connectWithSonos() {
        connectBtn.buttonTitle = L10n.Localizable.sonosConnecting
        guard let email = ServerSettings.syncingEmail(), let password = ServerSettings.syncingPassword() else {
            connectBtn.buttonTitle = L10n.Localizable.retry.localizedUppercase
            return
        }
        
        ApiServerHandler.shared.obtainToken(username: email, password: password, scope: "sonos") { token, _ in
            DispatchQueue.main.async { [weak self] in
                guard let token = token else {
                    self?.connectBtn.buttonTitle = L10n.Localizable.retry.localizedUppercase
                    SJUIUtils.showAlert(title: L10n.Localizable.sonosConnectionFailedTitle, message: L10n.Localizable.sonosConnectionFailedAccountLink, from: self)
                    
                    return
                }
                
                guard let strongSelf = self else { return }
                
                let fullUrl = strongSelf.callbackUri + "&code=" + token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                if let url = URL(string: fullUrl) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                else {
                    strongSelf.connectBtn.buttonTitle = L10n.Localizable.retry.localizedUppercase
                    SJUIUtils.showAlert(title: L10n.Localizable.sonosConnectionFailedTitle, message: L10n.Localizable.sonosConnectionFailedAppMissing, from: self)
                }
            }
        }
    }
    
    func signIntoPocketCasts(signInMode: Bool) {
        let signinPage = SyncSigninViewController()
        signinPage.delegate = self
        navigationController?.pushViewController(signinPage, animated: true)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Sign In Delegate
    
    func signingProcessCompleted() {
        navigationController?.popViewController(animated: true)
    }
}
