import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

protocol SyncSigninDelegate: AnyObject {
    func signingProcessCompleted()
}

class SyncSigninViewController: PCViewController, UITextFieldDelegate {
    @IBOutlet var emailField: ThemeableTextField! {
        didSet {
            emailField.placeholder = L10n.signInEmailAddressPrompt
            emailField.delegate = self
            emailField.addTarget(self, action: #selector(emailFieldDidChange), for: UIControl.Event.editingChanged)
        }
    }

    @IBOutlet var passwordField: ThemeableTextField! {
        didSet {
            passwordField.placeholder = L10n.signInPasswordPrompt
            passwordField.delegate = self
            passwordField.addTarget(self, action: #selector(passwordFieldDidChange), for: UIControl.Event.editingChanged)
        }
    }

    @IBOutlet var mainButton: ThemeableRoundedButton! {
        didSet {
            mainButton.setTitle(L10n.signIn, for: .normal)
            mainButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        }
    }

    @IBOutlet var emailBorderView: ThemeableSelectionView! {
        didSet {
            emailBorderView.style = .primaryField02
            emailBorderView.isSelected = true
        }
    }

    @IBOutlet var passwordBorderView: ThemeableSelectionView! {
        didSet {
            passwordBorderView.style = .primaryField02
            passwordBorderView.isSelected = false
        }
    }

    @IBOutlet var mailImage: UIImageView! {
        didSet {
            mailImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var keyImage: UIImageView! {
        didSet {
            keyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var contentView: UIView!
    @IBOutlet var errorView: UIView!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var forgotPasswordBtn: ThemeableUIButton! {
        didSet {
            forgotPasswordBtn.setTitle(L10n.signInForgotPassword, for: .normal)
            forgotPasswordBtn.style = .primaryInteractive01
        }
    }

    @IBOutlet var showPasswordBtn: UIButton! {
        didSet {
            showPasswordBtn.imageView?.tintColor = ThemeColor.primaryIcon03()
        }
    }

    @IBOutlet var mainButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            activityIndicatorView.isHidden = true
        }
    }

    weak var delegate: SyncSigninDelegate?

    var dismissOnCancel = false

    private var progressAlert: ShiftyLoadingAlert?

    private var totalPodcastsToImport = -1

    // MARK: - UIView Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.signIn
        mainButton.accessibilityLabel = L10n.signIn
        updateButtonState()

        if dismissOnCancel {
            let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped))
            closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
            navigationItem.leftBarButtonItem = closeButton
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back"), style: .done, target: self, action: #selector(closeTapped))
        }

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        originalButtonConstant = mainButtonBottomConstraint.constant

        Analytics.track(.signInShown)
    }

    deinit {
        emailField?.removeTarget(self, action: #selector(emailFieldDidChange), for: UIControl.Event.editingChanged)
        emailField?.delegate = nil

        passwordField?.delegate = nil
        passwordField?.removeTarget(self, action: #selector(passwordFieldDidChange), for: UIControl.Event.editingChanged)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        emailField.becomeFirstResponder()
        addCustomObserver(ServerNotifications.syncProgressPodcastCount, selector: #selector(syncProgressCountKnown(_:)))
        addCustomObserver(ServerNotifications.syncProgressPodcastUpto, selector: #selector(syncUpToChanged(_:)))
        addCustomObserver(ServerNotifications.syncProgressImportedPodcasts, selector: #selector(podcastsImported))
        addCustomObserver(ServerNotifications.syncCompleted, selector: #selector(syncCompleted))
        addCustomObserver(ServerNotifications.syncFailed, selector: #selector(syncCompleted))
        addCustomObserver(ServerNotifications.podcastRefreshFailed, selector: #selector(syncCompleted))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        removeAllCustomObservers()
    }

    @IBAction func toggleShowPassword(_ sender: Any) {
        passwordField.isSecureTextEntry.toggle()
        if passwordField.isSecureTextEntry {
            showPasswordBtn.setImage(UIImage(named: "eye-crossed"), for: .normal)
        } else {
            showPasswordBtn.setImage(UIImage(named: "eye"), for: .normal)
        }
    }

    @objc func closeTapped() {
        Analytics.track(.signInDismissed)

        if dismissOnCancel {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func signInTapped(_ sender: Any) {
        passwordField.resignFirstResponder()
        emailField.resignFirstResponder()
        performSignIn()
    }

    // MARK: - Syncing Progress

    @objc private func syncProgressCountKnown(_ notification: Notification) {
        if let number = notification.object as? NSNumber {
            totalPodcastsToImport = number.intValue
        }
    }

    @objc private func syncUpToChanged(_ notification: Notification) {
        guard let progressAlert = progressAlert, let number = notification.object as? NSNumber else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let upTo = number.intValue
            if self.totalPodcastsToImport > 0 {
                progressAlert.title = L10n.syncProgress(upTo.localized(), self.totalPodcastsToImport.localized())
                progressAlert.progress = CGFloat(upTo / self.totalPodcastsToImport)
            } else {
                // Used when the total number of podcasts to sync isn't known.
                progressAlert.title = upTo == 1 ? L10n.syncProgressUnknownCountSingular : L10n.syncProgressUnknownCountPluralFormat(upTo.localized())
            }
        }
    }

    @objc private func podcastsImported() {
        guard let progressAlert = progressAlert else { return }

        DispatchQueue.main.async {
            progressAlert.title = L10n.syncInProgress
        }
    }

    @objc private func syncCompleted() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.progressAlert?.hideAlert(false)
            self.progressAlert = nil

            if let delegate = self.delegate {
                delegate.signingProcessCompleted()
            } else {
                // if there's no delegate registered to handle a sign in finishing, just dismiss
                self.closeTapped()
            }
        }
    }

    // MARK: - UITextField Methods

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            performSignIn()
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
        if textField == emailField {
            emailBorderView.isSelected = true
            passwordBorderView.isSelected = false
        } else {
            emailBorderView.isSelected = false
            passwordBorderView.isSelected = true
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    @objc func emailFieldDidChange() {
        updateButtonState()
        hideErrorMessage()
    }

    @objc func passwordFieldDidChange() {
        updateButtonState()
        hideErrorMessage()
    }

    @IBAction func forgotPasswordTapped(_ sender: AnyObject) {
        let forgotPasswordPage = ForgotPasswordViewController()
        forgotPasswordPage.delegate = self
        navigationController?.pushViewController(forgotPasswordPage, animated: true)
    }

    private func performSignIn() {
        guard let username = emailField.text, let password = passwordField.text else { return }
        startSignIn(username, password: password)
    }

    private func startSignIn(_ username: String, password: String) {
        contentView.alpha = 0.3
        activityIndicatorView.startAnimating()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.isHidden = false

        mainButton.setTitle("", for: .normal)
        ApiServerHandler.shared.validateLogin(username: username, password: password) { success, userId, error in
            DispatchQueue.main.async {
                if !success {
                    Analytics.track(.userSignInFailed, properties: ["source": "password", "error_code": (error ?? .UNKNOWN).rawValue])

                    if error != .UNKNOWN, let message = error?.localizedDescription, !message.isEmpty {
                        self.showErrorMessage(message)
                    } else {
                        self.showErrorMessage(L10n.syncAccountError)
                    }

                    self.mainButton.setTitle(L10n.signIn, for: .normal)
                    self.contentView.alpha = 1
                    self.activityIndicatorView.stopAnimating()
                    self.progressAlert?.hideAlert(false)
                    self.progressAlert = nil
                    return
                }

                self.progressAlert = ShiftyLoadingAlert(title: L10n.syncAccountLogin)
                self.progressAlert?.showAlert(self, hasProgress: false, completion: {
                    // clear any previously stored tokens as we're signing in again and we might have one in Keychain already
                    SyncManager.clearTokensFromKeyChain()

                    self.handleSuccessfulSignIn(username, password: password, userId: userId)
                    RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
                    Settings.setPromotionFinishedAcknowledged(true)
                    Settings.setLoginDetailsUpdated()

                    NotificationCenter.postOnMainThread(notification: .userSignedIn)
                })
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }

    // MARK: - Theme changes

    override func handleThemeChanged() {
        mailImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        keyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        showPasswordBtn.imageView?.tintColor = ThemeColor.primaryIcon03()
    }

    // MARK: - Private Helpers

    private func handleSuccessfulSignIn(_ username: String, password: String, userId: String?) {
        ServerSettings.userId = userId
        ServerSettings.saveSyncingPassword(password)

        // we've signed in, set all our existing podcasts to
        // be non synced if the user never logged in before
        if ServerSettings.lastSyncTime == nil {
            DataManager.sharedManager.markAllPodcastsUnsynced()
        }

        SyncManager.syncReason = .login
        ServerSettings.clearLastSyncTime()
        ServerSettings.setSyncingEmail(email: username)

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)

        Analytics.track(.userSignedIn, properties: ["source": "password"])
    }

    private func showErrorMessage(_ message: String) {
        errorLabel.text = message
        errorView.isHidden = false
    }

    private func hideErrorMessage() {
        if errorView.isHidden { return }

        errorView.isHidden = true
    }

    private func updateButtonState() {
        mainButton.isEnabled = validFields()
        mainButton.buttonStyle = mainButton.isEnabled ? .primaryInteractive01 : .primaryInteractive01Disabled
    }

    private func validFields() -> Bool {
        if let email = emailField.text, let password = passwordField.text, email.contains("@") {
            return email.count >= 3 && password.count >= 3
        }

        return false
    }

    private var originalButtonConstant: CGFloat = 60
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            mainButtonBottomConstraint.constant = originalButtonConstant + keyboardSize.height
            var animationDuration = 0.3
            if let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) {
                animationDuration = keyboardDuration
            }

            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        mainButtonBottomConstraint.constant = originalButtonConstant
        var animationDuration = 0.3
        if let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) {
            animationDuration = keyboardDuration
        }
        UIView.animate(withDuration: animationDuration, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension SyncSigninViewController: ForgotPasswordDelegate {
    func handlePasswordResetSuccess() {
        navigationController?.popToViewController(self, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {

            SJUIUtils.showAlert(title: L10n.profileSendingResetEmailConfTitle, message: L10n.profileSendingResetEmailConfMsg, from: self)
        }
    }
}
