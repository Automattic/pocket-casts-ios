import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

protocol CreateAccountDelegate: AnyObject {
    func handleAccountCreated()
}

class NewEmailViewController: PCViewController, UITextFieldDelegate {
    weak var delegate: CreateAccountDelegate?

    @IBOutlet var emailField: ThemeableTextField! {
        didSet {
            emailField.delegate = self
            emailField.addTarget(self, action: #selector(emailFieldDidChange), for: UIControl.Event.editingChanged)
            emailField.placeholder = L10n.signInEmailAddressPrompt
        }
    }

    @IBOutlet var contentView: ThemeableView!
    @IBOutlet var nextButton: ThemeableRoundedButton! {
        didSet {
            nextButton.isEnabled = false
            nextButton.buttonStyle = .primaryInteractive01Disabled
            nextButton.setTitle(L10n.next, for: .normal)
        }
    }

    @IBOutlet var statusImage: UIImageView! {
        didSet {
            statusImage.tintColor = AppTheme.colorForStyle(.support02)
        }
    }

    @IBOutlet var emailBorderView: ThemeableSelectionView! {
        didSet {
            emailBorderView.layer.borderWidth = 2
            emailBorderView.layer.cornerRadius = 6
            emailBorderView.style = .primaryField02
            emailBorderView.isSelected = true
        }
    }

    @IBOutlet var passwordBorderView: ThemeableSelectionView! {
        didSet {
            passwordBorderView.style = .primaryField02
            passwordBorderView.isSelected = false
            passwordBorderView.layer.borderWidth = 2
            passwordBorderView.layer.cornerRadius = 6
        }
    }

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.text = "• " + L10n.changePasswordLengthError
        }
    }

    @IBOutlet var passwordField: ThemeableTextField! {
        didSet {
            passwordField.delegate = self
            passwordField.addTarget(self, action: #selector(NewEmailViewController.passwordFieldDidChange), for: UIControl.Event.editingChanged)
            passwordField.placeholder = L10n.signInPasswordPrompt
        }
    }

    @IBOutlet var showPasswordButton: UIButton! {
        didSet {
            showPasswordButton.tintColor = ThemeColor.primaryIcon03()
        }
    }

    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
        }
    }

    @IBOutlet var mailImage: UIImageView! {
        didSet {
            mailImage.tintColor = ThemeColor.primaryField03Active()
        }
    }

    @IBOutlet var keyImage: UIImageView! {
        didSet {
            keyImage.tintColor = ThemeColor.primaryField03Active()
        }
    }

    var newSubscription: NewSubscription
    weak var accountUpdatedDelegate: AccountUpdatedDelegate?

    init(newSubscription: NewSubscription) {
        self.newSubscription = newSubscription
        super.init(nibName: "NewEmailViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.createAccount
        activityIndicator.isHidden = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back"), style: .done, target: self, action: #selector(backTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        originalButtonConstant = nextButtonBottomConstraint.constant

        updateButtonState()
        Analytics.track(.createAccountShown)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        emailField.becomeFirstResponder()
    }

    deinit {
        emailField?.removeTarget(self, action: #selector(emailFieldDidChange), for: UIControl.Event.editingChanged)
        emailField?.delegate = nil
        passwordField?.removeTarget(self, action: #selector(passwordFieldDidChange), for: .editingChanged)
        passwordField?.delegate = nil

        NotificationCenter.default.removeObserver(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    override func handleThemeChanged() {
        showPasswordButton.tintColor = ThemeColor.primaryIcon03()
        mailImage.tintColor = ThemeColor.primaryField03Active()
        keyImage.tintColor = ThemeColor.primaryField03Active()
        statusImage.tintColor = ThemeColor.support02()
    }

    // MARK: - Actions

    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
        Analytics.track(.createAccountDismissed)
    }

    @IBAction func nextTapped(_ sender: Any) {
        guard let email = emailField.text, let password = passwordField.text else { return }
        startRegister(email, password: password)
    }

    @IBAction func toggleHidePassword(_ sender: Any) {
        passwordField.isSecureTextEntry.toggle()
        if passwordField.isSecureTextEntry {
            showPasswordButton.setImage(UIImage(named: "eye-crossed"), for: .normal)
        } else {
            showPasswordButton.setImage(UIImage(named: "eye"), for: .normal)
        }
    }

    private func startRegister(_ username: String, password: String) {
        Analytics.track(.createAccountNextButtonTapped)

        passwordBorderView.layer.borderColor = ThemeColor.primaryUi05().cgColor
        contentView.alpha = 0.3
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        nextButton.setTitle("", for: .normal)

        ApiServerHandler.shared.registerAccount(username: username, password: password) { success, userId, error in
            DispatchQueue.main.async {
                self.contentView.alpha = 1
                self.activityIndicator.stopAnimating()

                if !success {
                    Analytics.track(.userAccountCreationFailed, properties: ["error_code": (error ?? .UNKNOWN).rawValue])

                    FileLog.shared.addMessage("Failed to register new account")
                    if error != .UNKNOWN, let message = error?.localizedDescription, !message.isEmpty {
                        FileLog.shared.addMessage(message)
                        self.showErrorMessage(message)
                    } else {
                        self.showErrorMessage(L10n.accountRegistrationFailed)
                    }
                    self.nextButton.setTitle(L10n.next, for: .normal)
                    return
                }

                FileLog.shared.addMessage("Registered new account for \(username)")
                self.saveUsernameAndPassword(username, password: password, userId: userId)

                SyncManager.syncReason = .accountCreated
                RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)

                Settings.setLoginDetailsUpdated()

                // Let a delegate decide what to do next
                if let delegate = self.delegate {
                    delegate.handleAccountCreated()
                    return
                }
            }
        }
    }

    // MARK: - Private helpers

    private func showErrorMessage(_ message: String) {
        infoLabel.text = message
        infoLabel.style = .support05
        if message.lowercased().contains("email") {
            emailBorderView.isSelected = true
            emailBorderView.selectedStyle = .support05
        }
        if message.lowercased().contains("password") {
            passwordBorderView.isSelected = true
            passwordBorderView.selectedStyle = .support05
        }
    }

    private func hideErrorMessage() {
        infoLabel.style = .primaryText01
    }

    private func saveUsernameAndPassword(_ username: String, password: String, userId: String?) {
        ServerSettings.userId = userId
        ServerSettings.saveSyncingPassword(password)

        // we've signed in, set all our existing podcasts to be non synced
        DataManager.sharedManager.markAllPodcastsUnsynced()

        ServerSettings.clearLastSyncTime()
        ServerSettings.setSyncingEmail(email: username)

        NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
        NotificationCenter.postOnMainThread(notification: .userSignedIn)
    }

    // MARK: - UITextField Methods

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            startRegister(emailField.text ?? "", password: passwordField.text ?? "")
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
        if textField == emailField {
            emailBorderView.selectedStyle =
                .primaryField03Active
            emailBorderView.isSelected = true
            passwordBorderView.isSelected = false
        } else {
            passwordBorderView.selectedStyle = .primaryField03Active
            emailBorderView.isSelected = false
            passwordBorderView.isSelected = true
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    @objc func emailFieldDidChange() {
        updateButtonState()
    }

    @objc func passwordFieldDidChange() {
        updateButtonState()
        hideErrorMessage()
    }

    private func updateButtonState() {
        nextButton.isEnabled = validEmail() && validPassword()

        nextButton.buttonStyle = nextButton.isEnabled ? .primaryInteractive01 : .primaryInteractive01Disabled
        statusImage.isHidden = !validEmail()
    }

    private func validEmail() -> Bool {
        if let email = emailField.text, email.contains("@") {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: email)
        }

        return false
    }

    private func validPassword() -> Bool {
        if let password = passwordField.text {
            return password.count >= 3
        }
        return false
    }

    private var originalButtonConstant: CGFloat = 49
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            nextButtonBottomConstraint.constant = originalButtonConstant + keyboardSize.height
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
        nextButtonBottomConstraint.constant = originalButtonConstant
        var animationDuration = 0.3
        if let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) {
            animationDuration = keyboardDuration
        }
        UIView.animate(withDuration: animationDuration, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
