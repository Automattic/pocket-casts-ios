
import UIKit

class NewPasswordViewController: UIViewController, UITextFieldDelegate {
    var emailAddress: String!
    @IBOutlet var contentView: UIView!
    @IBOutlet var passwordBorderView: UIView! {
        didSet {
            passwordBorderView.layer.borderWidth = 2
            passwordBorderView.layer.borderColor = ThemeColor.primaryField03Active().cgColor
            passwordBorderView.layer.cornerRadius = 6
            passwordBorderView.backgroundColor = ThemeColor.primaryField02Active()
        }
    }

    @IBOutlet var infoLabel: UILabel! {
        didSet {
            infoLabel.attributedText = NSMutableAttributedString(string: "\u{0095}Must be at least 6 characters")
        }
    }

    @IBOutlet var passwordField: UITextField! {
        didSet {
            passwordField.delegate = self
            passwordField.addTarget(self, action: #selector(NewPasswordViewController.passwordFieldDidChange), for: UIControl.Event.editingChanged)
        }
    }

    @IBOutlet var showPasswordButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
        }
    }

    var newSubscription: NewSubscription!
    var addToMailList: Bool = false

    init(email: String, addToMailList: Bool, newSubscription: NewSubscription) {
        emailAddress = email
        self.addToMailList = addToMailList
        self.newSubscription = newSubscription
        super.init(nibName: "NewPasswordViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose a Password"
        activityIndicator.isHidden = true

        passwordField.keyboardType = .emailAddress
        passwordField.becomeFirstResponder()
        passwordField.isSecureTextEntry = true
        updateButtonState()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back"), style: .done, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem?.tintColor = ThemeColor.primaryIcon01()
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        originalButtonConstant = nextButtonBottomConstraint.constant
    }

    deinit {
        passwordField?.delegate = nil
        passwordField?.removeTarget(self, action: #selector(NewPasswordViewController.passwordFieldDidChange), for: UIControl.Event.editingChanged)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Actions

    @IBAction func toggleHidePassword(_ sender: Any) {
        passwordField.isSecureTextEntry.toggle()
        if passwordField.isSecureTextEntry {
            showPasswordButton.setImage(UIImage(named: "eye-crossed"), for: .normal)
        } else {
            showPasswordButton.setImage(UIImage(named: "eye"), for: .normal)
        }
    }

    @IBAction func nextTapped(_ sender: Any) {
        guard let password = passwordField.text else { return }
        startRegister(emailAddress, password: password)
    }

    @objc func closeTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UITextField Methods

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func passwordFieldDidChange() {
        updateButtonState()
        hideErrorMessage()
    }

    // MARK: - Private Helpers

    private func saveUsernameAndPassword(_ username: String, password: String) {
        Lockbox.setString(password, forKey: Constants.Values.syncingPasswordKey, accessibility: kSecAttrAccessibleAlways)

        // we've signed in, set all our existing podcasts to be non synced
        DataManager.sharedManager.markAllPodcastsUnsynced()

        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.lastSyncTime)
        UserDefaults.standard.set(username, forKey: Constants.UserDefaults.syncingEmail)
    }

    private func showErrorMessage(_ message: String) {
        infoLabel.textColor = UIColor.red
        passwordField.textColor = UIColor.red
    }

    private func hideErrorMessage() {
        infoLabel.textColor = UIColor.black
        passwordField.textColor = UIColor.black
    }

    private func updateButtonState() {
        nextButton.isEnabled = validFields()
        nextButton.backgroundColor = nextButton.isEnabled ? ThemeColor.primaryIcon01() : ThemeColor.secondaryIcon01()
    }

    private func validFields() -> Bool {
        if let password = passwordField.text {
            return password.count >= 3
        }
        return false
    }

    private func startRegister(_ username: String, password: String) {
        passwordBorderView.layer.borderColor = ThemeColor.secondaryIcon01().cgColor
        contentView.alpha = 0.3
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        ServerManager.shared().regiserForSyncing(withUsername: username, andPassword: password) { response in

            self.contentView.alpha = 1
            self.activityIndicator.stopAnimating()
            if !response.success {
                FileLog.shared.addMessage("Failed to register new account")
                // TODO: the server response isn't correct....yet!
                if let message = response.message, message.count > 0 {
                    // TODO: go back to emailVC if in use
                    self.showErrorMessage(message)
                } else {
                    self.showErrorMessage("Registration failed, please try again later")
                }

                return
            }
            FileLog.shared.addMessage("Registered new account for \(username)")
            self.saveUsernameAndPassword(username, password: password)
            PodcastManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)

            if let newSubscription = self.newSubscription, newSubscription.iap_identifier.count > 0 {
                let confirmPaymentVC = ConfirmPaymentViewController(newSubscription: newSubscription)
                self.navigationController?.pushViewController(confirmPaymentVC, animated: true)
            } else { // Free account
                let accountCreatedVC = AccountUpdatedViewController()
                accountCreatedVC.titleText = "Account Created"
                accountCreatedVC.detailText = "Welcome to Pocket Casts!"
                accountCreatedVC.imageName = AppTheme.accountCreatedImageName
                self.navigationController?.pushViewController(accountCreatedVC, animated: true)
            }

            // TODO:
            //  if let delegate = self.delegate {
            //     delegate.userDidRegister()
            // }
            // TODO: add to mail list if needed

            //
        }
    }

    // MARK: - Keyboard show/hide functions

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
}
