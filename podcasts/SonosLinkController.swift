import PocketCastsServer
import PocketCastsUtils
import UIKit

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
                } else {
                    self?.signIntoPocketCasts(signInMode: true)
                }
            }
        }
    }

    @IBOutlet var createBtn: ShiftyRoundButton! {
        didSet {
            createBtn.buttonTitle = L10n.createAccount
            createBtn.buttonTapped = { [weak self] in
                self?.signIntoPocketCasts(signInMode: false)
            }
        }
    }

    @IBOutlet var mainMessage: UILabel!

    var callbackUri = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.sonosConnectPrompt
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(SonosLinkController.cancelTapped))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if SyncManager.isUserLoggedIn() {
            mainMessage.text = L10n.sonosConnectionPrivacyNotice
            connectBtn.buttonTitle = L10n.sonosConnectAction
            createBtn.isHidden = true
        } else {
            mainMessage.text = L10n.sonosConnectionSignInPrompt
            connectBtn.buttonTitle = L10n.signIn.localizedUppercase
            createBtn.isHidden = false
        }
    }

    func connectWithSonos() {
        connectBtn.buttonTitle = L10n.sonosConnecting
        guard ServerSettings.syncingEmail() != nil else {
            connectBtn.buttonTitle = L10n.retry.localizedUppercase
            return
        }

        Task {
            let token = try? await AuthenticationHelper.refreshLogin(scope: .sonos)

            DispatchQueue.main.async { [weak self] in
                guard let token = token else {
                    self?.connectBtn.buttonTitle = L10n.retry.localizedUppercase
                    SJUIUtils.showAlert(title: L10n.sonosConnectionFailedTitle, message: L10n.sonosConnectionFailedAccountLink, from: self)
                    return
                }

                FileLog.shared.addMessage("Sync Token refreshed source: Sonos")
                guard let strongSelf = self else { return }

                let fullUrl = strongSelf.callbackUri + "&code=" + token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                if let url = URL(string: fullUrl) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    strongSelf.connectBtn.buttonTitle = L10n.retry.localizedUppercase
                    SJUIUtils.showAlert(title: L10n.sonosConnectionFailedTitle, message: L10n.sonosConnectionFailedAppMissing, from: self)
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
