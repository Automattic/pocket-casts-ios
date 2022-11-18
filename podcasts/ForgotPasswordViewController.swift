import PocketCastsServer
import UIKit

protocol ForgotPasswordDelegate: AnyObject {
    func handlePasswordResetSuccess()
}
class ForgotPasswordViewController: PCViewController, UITextFieldDelegate {
    weak var delegate: ForgotPasswordDelegate?

    @IBOutlet var resetPasswordBtn: ThemeableRoundedButton! {
        didSet {
            resetPasswordBtn.setTitle(L10n.profileResetPassword, for: .normal)
            resetPasswordBtn.buttonStyle = .primaryInteractive01
        }
    }

    @IBOutlet var emailField: ThemeableTextField! {
        didSet {
            emailField.placeholder = L10n.signInEmailAddressPrompt
            emailField.delegate = self
            emailField.addTarget(self, action: #selector(ForgotPasswordViewController.emailFieldDidChange), for: UIControl.Event.editingChanged)
        }
    }

    @IBOutlet var emailBorderView: ThemeableSelectionView! {
        didSet {
            emailBorderView.isSelected = true
            emailBorderView.layer.cornerRadius = 6
            emailBorderView.layer.borderWidth = 2
        }
    }

    @IBOutlet var messageView: UIView!
    @IBOutlet var errorMessage: ThemeableLabel! {
        didSet {
            errorMessage.style = .support05
        }
    }

    @IBOutlet var errorImage: UIImageView! {
        didSet {
            errorImage.tintColor = AppTheme.colorForStyle(.support05)
        }
    }

    @IBOutlet var mailImage: UIImageView! {
        didSet {
            mailImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var mainButtonTopSpace: NSLayoutConstraint!

    private var progressAlert: ShiftyLoadingAlert?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.profileResetPassword
        resetPasswordBtn.isEnabled = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back"), style: .done, target: self, action: #selector(closeTapped))
        Analytics.track(.forgotPasswordShown)
    }

    deinit {
        emailField?.delegate = nil
        emailField?.removeTarget(self, action: #selector(ForgotPasswordViewController.emailFieldDidChange), for: UIControl.Event.editingChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButtonState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.tintColor = AppTheme.navBarIconsColor()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Analytics.track(.forgotPasswordDismissed)
    }

    @objc func emailFieldDidChange() {
        updateButtonState()
        hideErrorMessage()
    }

    override func handleThemeChanged() {
        errorImage.tintColor = AppTheme.colorForStyle(.support05)
        mailImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
    }

    @IBAction func performResetPassword(_ sender: Any) {
        guard let email = emailField.text else { return }

        progressAlert = ShiftyLoadingAlert(title: L10n.profileSendingResetEmail)
        progressAlert?.showAlert(self, hasProgress: false, completion: {
            self.startPasswordReset(email)
        })
    }

    private func startPasswordReset(_ email: String) {
        emailField.resignFirstResponder()

        ApiServerHandler.shared.forgotPassword(email: email) { success, error in
            DispatchQueue.main.async {
                self.progressAlert?.hideAlert(false)
                self.progressAlert = nil

                if !success {
                    if error != .UNKNOWN, let message = error?.localizedDescription, !message.isEmpty {
                        self.showErrorMessage(message)
                    } else {
                        self.showErrorMessage(L10n.profileSendingResetEmailFailed)
                    }

                    return
                }

                Analytics.track(.userPasswordReset)

                guard let delegate = self.delegate else {
                    self.navigationController?.popViewController(animated: true)
                    SJUIUtils.showAlert(title: L10n.profileSendingResetEmailConfTitle, message: L10n.profileSendingResetEmailConfMsg, from: self)
                    return
                }

                delegate.handlePasswordResetSuccess()
            }
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage.text = message
        mainButtonTopSpace.constant = 50
        messageView.isHidden = false
    }

    private func hideErrorMessage() {
        messageView.isHidden = true
    }

    private func updateButtonState() {
        resetPasswordBtn.isEnabled = validFields()
        resetPasswordBtn.buttonStyle = resetPasswordBtn.isEnabled ? .primaryInteractive01 : .primaryInteractive01Disabled
    }

    private func validFields() -> Bool {
        if let email = emailField.text {
            return email.count >= 3 && email.contains("@")
        }

        return false
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }

    @objc func closeTapped() {
        emailField.resignFirstResponder()
        navigationController?.popViewController(animated: true)
    }
}
