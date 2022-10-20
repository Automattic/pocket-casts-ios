import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

protocol SyncSigninDelegate: AnyObject {
    func signingProcessCompleted()
}

class SyncSigninViewController: PCViewController, UITextFieldDelegate {
    private let authSource = AuthenticationSource.password.rawValue
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

    private var progressAlert: SyncLoadingAlert?

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

        self.progressAlert = SyncLoadingAlert()
        self.progressAlert?.showAlert(self, hasProgress: false, completion: {
            Task {
                do {
                    try await AuthenticationHelper.validateLogin(username: username, password: password)
                }
                catch {
                    DispatchQueue.main.async {
                        self.handleError(error)
                    }
                }
            }
        })
    }

    private func handleError(_ error: Error) {
        let error = (error as? APIError) ?? APIError.UNKNOWN
        Analytics.track(.userSignInFailed, properties: ["source": self.authSource, "error_code": error.rawValue])

        var message = L10n.syncAccountError
        if !error.isGenericError, !error.localizedDescription.isEmpty {
            message = error.localizedDescription
        }

        showErrorMessage(message)
        mainButton.setTitle(L10n.signIn, for: .normal)
        contentView.alpha = 1
        activityIndicatorView.stopAnimating()
        progressAlert?.hideAlert(false)
        progressAlert = nil
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
