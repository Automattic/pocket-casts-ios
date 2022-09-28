import PocketCastsServer
import UIKit

protocol ChangeEmailDelegate: AnyObject {
    func emailChanged()
}

class ChangeEmailViewController: PCViewController, UITextFieldDelegate {
    weak var delegate: ChangeEmailDelegate?
    @IBOutlet var contentView: ThemeableView! {
        didSet {
            contentView.style = .primaryUi02
        }
    }

    @IBOutlet var currentEmailLabel: ThemeableLabel! {
        didSet {
            currentEmailLabel.text = L10n.currentEmailPrompt
        }
    }

    @IBOutlet var emailInfoLabel: ThemeableLabel! {
        didSet {
            emailInfoLabel.style = .primaryText02
            emailInfoLabel.text = L10n.currentEmailPrompt.localizedCapitalized
        }
    }

    @IBOutlet var emailField: ThemeableTextField! {
        didSet {
            emailField.placeholder = L10n.newEmailAddressPrompt
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
            mainButton.isEnabled = false
            mainButton.buttonStyle = .primaryInteractive01Disabled
            mainButton.textStyle = .primaryInteractive02
            mainButton.setTitle(L10n.confirm, for: .normal)
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

    @IBOutlet var keyImage: UIImageView! {
        didSet {
            keyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var mailImage: UIImageView! {
        didSet {
            mailImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var errorView: UIView!
    @IBOutlet var errorLabel: ThemeableLabel! {
        didSet {
            errorLabel.style = .support05
        }
    }

    @IBOutlet var statusImage: UIImageView! {
        didSet {
            statusImage.tintColor = AppTheme.colorForStyle(.support02)
        }
    }

    @IBOutlet var showPasswordBtn: UIButton! {
        didSet {
            showPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        }
    }

    @IBOutlet var mainButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            activityIndicatorView.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.changeEmail
        currentEmailLabel.text = ServerSettings.syncingEmail()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(backTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        originalButtonConstant = mainButtonBottomConstraint.constant

        updateButtonState()
    }

    deinit {
        emailField?.removeTarget(self, action: #selector(emailFieldDidChange), for: UIControl.Event.editingChanged)
        emailField?.delegate = nil
        passwordField?.removeTarget(self, action: #selector(passwordFieldDidChange), for: .editingChanged)
        passwordField?.delegate = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        emailField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    override func handleThemeChanged() {
        showPasswordBtn.tintColor = AppTheme.colorForStyle(.primaryIcon03)
        mailImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        keyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        statusImage.tintColor = AppTheme.colorForStyle(.support02)
    }

    // MARK: - Actions

    @objc func backTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func toggleHidePassword(_ sender: Any) {
        passwordField.isSecureTextEntry.toggle()
        if passwordField.isSecureTextEntry {
            showPasswordBtn.setImage(UIImage(named: "eye-crossed"), for: .normal)
        } else {
            showPasswordBtn.setImage(UIImage(named: "eye"), for: .normal)
        }
    }

    @IBAction func changeTapped(_ sender: Any) {
        passwordField.resignFirstResponder()
        emailField.resignFirstResponder()
        changePassword()
    }

    @objc func changePassword() {
        guard let newEmail = emailField.text, let password = passwordField.text else {
            errorView.isHidden = false
            return
        }

        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        mainButton.setTitle("", for: .normal)
        contentView.alpha = 0.3
        ApiServerHandler.shared.changeEmailRequest(newEmail: newEmail, password: password, completion: { success in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
            }
            if success {
                Analytics.track(.userEmailUpdated)

                ServerSettings.setSyncingEmail(email: newEmail)
                self.delegate?.emailChanged()
                Settings.setLoginDetailsUpdated()
                DispatchQueue.main.async {
                    let updatedVC = AccountUpdatedViewController()
                    updatedVC.titleText = L10n.changeEmailConf
                    updatedVC.detailText = L10n.funnyConfMsg
                    updatedVC.imageName = AppTheme.changedEmailImageName
                    self.navigationController?.pushViewController(updatedVC, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self.mainButton.setTitle(L10n.confirm, for: .normal)
                    self.errorView.isHidden = false
                    self.contentView.alpha = 1
                }
            }
        })
    }

    // MARK: - UITextField Methods

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
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

    // MARK: - Private helpers

    @objc func emailFieldDidChange() {
        updateButtonState()
    }

    @objc func passwordFieldDidChange() {
        updateButtonState()
        hideErrorMessage()
    }

    private func updateButtonState() {
        mainButton.isEnabled = validFields()
        statusImage.isHidden = !validFields()
        mainButton.buttonStyle = mainButton.isEnabled ? .primaryInteractive01 : .primaryInteractive01Disabled
    }

    private func validFields() -> Bool {
        if let email = emailField.text, email.contains("@") {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: email)
        }

        return false
    }

    private func hideErrorMessage() {
        if errorView.isHidden { return }

        errorView.isHidden = true
    }

    // MARK: Keyboard management

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

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
