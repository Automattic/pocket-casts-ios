import PocketCastsServer
import PocketCastsUtils
import UIKit

class ChangePasswordViewController: PCViewController, UITextFieldDelegate {
    @IBOutlet var contentView: ThemeableView! {
        didSet {
            contentView.style = .primaryUi02
        }
    }

    @IBOutlet var currentField: ThemeableTextField! {
        didSet {
            currentField.placeholder = L10n.currentPasswordPrompt
            currentField.delegate = self
            currentField.addTarget(self, action: #selector(ChangePasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        }
    }

    @IBOutlet var newField: ThemeableTextField! {
        didSet {
            newField.placeholder = L10n.newPasswordPrompt
            newField.delegate = self
            newField.addTarget(self, action: #selector(ChangePasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        }
    }

    @IBOutlet var confirmField: ThemeableTextField! {
        didSet {
            confirmField.placeholder = L10n.confirmNewPasswordPrompt
            confirmField.delegate = self
            confirmField.addTarget(self, action: #selector(ChangePasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
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

    @IBOutlet var currentBorderView: ThemeableSelectionView! {
        didSet {
            currentBorderView.isSelected = true
            currentBorderView.style = .primaryField02
        }
    }

    @IBOutlet var newBorderView: ThemeableSelectionView! {
        didSet {
            newBorderView.isSelected = false
            newBorderView.style = .primaryField02
        }
    }

    @IBOutlet var confirmBorderView: ThemeableSelectionView! {
        didSet {
            confirmBorderView.isSelected = false
            confirmBorderView.style = .primaryField02
        }
    }

    @IBOutlet var errorView: ThemeableView!
    @IBOutlet var errorLabel: ThemeableLabel! {
        didSet {
            errorLabel.style = .support05
        }
    }

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.attributedText = NSMutableAttributedString(string: "• " + L10n.changePasswordLengthError)
        }
    }

    @IBOutlet var showCurrentPasswordBtn: UIButton! {
        didSet {
            showCurrentPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        }
    }

    @IBOutlet var showNewPasswordBtn: UIButton! {
        didSet {
            showNewPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        }
    }

    @IBOutlet var showConfirmPasswordBtn: UIButton! {
        didSet {
            showConfirmPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        }
    }

    @IBOutlet var currentKeyImage: UIImageView! {
        didSet {
            currentKeyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var newKeyImage: UIImageView! {
        didSet {
            newKeyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
        }
    }

    @IBOutlet var confirmKeyImage: UIImageView! {
        didSet {
            confirmKeyImage.tintColor = AppTheme.colorForStyle(.primaryField03Active)
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
        title = L10n.changePassword

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(backTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        originalButtonConstant = mainButtonBottomConstraint.constant

        updateButtonState()
    }

    deinit {
        currentField.removeTarget(self, action: #selector(ChangePasswordViewController.textFieldDidChange), for: .editingChanged)
        newField.removeTarget(self, action: #selector(ChangePasswordViewController.textFieldDidChange), for: .editingChanged)
        confirmField.removeTarget(self, action: #selector(ChangePasswordViewController.textFieldDidChange), for: .editingChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        currentField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        currentField.resignFirstResponder()
        newField.resignFirstResponder()
        confirmField.resignFirstResponder()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    override func handleThemeChanged() {
        showNewPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        showConfirmPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        showCurrentPasswordBtn.tintColor = ThemeColor.primaryIcon03()
        currentKeyImage.tintColor = ThemeColor.primaryField03Active()
        newKeyImage.tintColor = ThemeColor.primaryField03Active()
        confirmKeyImage.tintColor = ThemeColor.primaryField03Active()
    }

    // MARK: - Actions

    @objc func backTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func toggleHidePassword(_ sender: UIButton) {
        let tappedButton = sender
        var textFieldToToggle: UITextField!
        if tappedButton == showCurrentPasswordBtn {
            textFieldToToggle = currentField
        } else if tappedButton == showNewPasswordBtn {
            textFieldToToggle = newField
        } else if tappedButton == showConfirmPasswordBtn {
            textFieldToToggle = confirmField
        }

        if let textFieldToToggle = textFieldToToggle {
            textFieldToToggle.isSecureTextEntry.toggle()
            if textFieldToToggle.isSecureTextEntry {
                tappedButton.setImage(UIImage(named: "eye-crossed"), for: .normal)
            } else {
                tappedButton.setImage(UIImage(named: "eye"), for: .normal)
            }
        }
    }

    @IBAction func confirmTapped(_ sender: UIButton) {
        currentField.resignFirstResponder()
        newField.resignFirstResponder()
        confirmField.resignFirstResponder()
        changePassword()
    }

    @objc func changePassword() {
        guard let currentPassword = currentField.text, let newPassword = newField.text else {
            errorView.isHidden = false
            return
        }

        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        mainButton.setTitle("", for: .normal)
        contentView.alpha = 0.3
        ApiServerHandler.shared.changePasswordRequest(currentPassword: currentPassword, newPassword: newPassword, completion: { success in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
            }
            if success {
                Analytics.track(.userPasswordUpdated)

                Settings.setLoginDetailsUpdated()
                ServerSettings.saveSyncingPassword(newPassword)
                DispatchQueue.main.async {
                    let updatedVC = AccountUpdatedViewController()
                    updatedVC.titleText = L10n.changePasswordConf
                    updatedVC.detailText = L10n.funnyConfMsg
                    updatedVC.imageName = AppTheme.passwordChangedImageName
                    self.navigationController?.pushViewController(updatedVC, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self.mainButton.setTitle(L10n.confirm, for: .normal)
                    self.errorView.isHidden = false
                    self.errorLabel.text = L10n.changePasswordError
                    self.contentView.alpha = 1
                }
            }
        })
    }

    // MARK: - UITextField Methods

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
        if textField == currentField {
            currentBorderView.isSelected = true
            newBorderView.isSelected = false
            confirmBorderView.isSelected = false
            showNewPasswordBtn.isHidden = true
            showCurrentPasswordBtn.isHidden = false
            showConfirmPasswordBtn.isHidden = true
        } else if textField == newField {
            currentBorderView.isSelected = false
            newBorderView.isSelected = true
            confirmBorderView.isSelected = false
            showNewPasswordBtn.isHidden = false
            showCurrentPasswordBtn.isHidden = true
            showConfirmPasswordBtn.isHidden = true
        } else if textField == confirmField {
            currentBorderView.isSelected = false
            newBorderView.isSelected = false
            confirmBorderView.isSelected = true
            showNewPasswordBtn.isHidden = true
            showCurrentPasswordBtn.isHidden = true
            showConfirmPasswordBtn.isHidden = false
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == currentField {
            newField.becomeFirstResponder()
        } else if textField == newField {
            confirmField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return true
    }

    // MARK: - Private helpers

    @objc func textFieldDidChange() {
        updateButtonState()
    }

    @objc func confirmFieldDidChange() {
        updateButtonState()
    }

    private func updateButtonState() {
        mainButton.isEnabled = validFields()
        mainButton.buttonStyle = mainButton.isEnabled ? .primaryInteractive01 : .primaryInteractive01Disabled
    }

    private func validFields() -> Bool {
        guard let currentPassword = currentField.text, let newPassword = newField.text, let confirmPassword = confirmField.text, currentPassword.count > 5, newPassword.count > 5, confirmPassword.count > 5 else {
            errorView.isHidden = true
            return false
        }

        if newField.text != confirmField.text {
            errorLabel.text = L10n.changePasswordErrorMismatch
            errorView.isHidden = false
            return false
        }
        errorView.isHidden = true
        return true
    }

    // MARK: Keyboard management

    private var originalButtonConstant: CGFloat = 49
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
