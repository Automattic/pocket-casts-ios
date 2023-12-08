import PocketCastsServer
import UIKit

protocol PromotionRedeemedDelegate: AnyObject {
    func promotionRedeemed(message: String)
}

class PromotionViewController: UIViewController, SyncSigninDelegate, AccountUpdatedDelegate {
    weak var delegate: PromotionRedeemedDelegate?
    @IBOutlet var titleLabel: ThemeableLabel!
    @IBOutlet var descriptionLabel: ThemeableLabel! {
        didSet {
            descriptionLabel.style = .primaryText02
        }
    }

    @IBOutlet var secondDescriptionLabel: ThemeableLabel! {
        didSet {
            secondDescriptionLabel.style = .primaryText02
        }
    }

    @IBOutlet var centreImageView: ThemeableImageView!
    @IBOutlet var activityIndicator: ThemeLoadingIndicator!

    @IBOutlet var buttonContainerView: TopShadowView!
    @IBOutlet var doneButton: UIButton! {
        didSet {
            doneButton.layer.cornerRadius = 12
            doneButton.tintColor = AppTheme.colorForStyle(.primaryInteractive01)
        }
    }

    @IBOutlet var createAccountWithPromoButton: ThemeableRoundedButton! {
        didSet {
            createAccountWithPromoButton.layer.cornerRadius = 12
            createAccountWithPromoButton.tintColor = AppTheme.colorForStyle(.primaryInteractive01)
        }
    }

    @IBOutlet var signInWithPromoButton: ThemeableRoundedButton! {
        didSet {
            signInWithPromoButton.layer.cornerRadius = 12
            signInWithPromoButton.shouldFill = false
            signInWithPromoButton.tintColor = AppTheme.colorForStyle(.primaryInteractive01)
        }
    }

    @IBOutlet var upgradeToPlusButton: ThemeableRoundedButton! {
        didSet {
            upgradeToPlusButton.layer.cornerRadius = 12
            upgradeToPlusButton.shouldFill = false
            upgradeToPlusButton.tintColor = AppTheme.colorForStyle(.primaryInteractive01)
        }
    }

    @IBOutlet var signUpNoPromoButton: ThemeableRoundedButton! {
        didSet {
            signUpNoPromoButton.layer.cornerRadius = 12
            signUpNoPromoButton.shouldFill = false
            signUpNoPromoButton.tintColor = AppTheme.colorForStyle(.primaryInteractive01)
        }
    }

    var promoCode: String?
    var serverMessage: String?
    var userDidSignIn = false
    enum PromoStatusType: Int { case validating = 0, codeExpired, codeInvalid, existingPlusUser, signIn, codeReused }

    private var promoStatus: PromoStatusType = .validating {
        didSet {
            updateDisplayMessage()
        }
    }

    private var userLoginNotification: NSObjectProtocol? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ThemeableView)?.style = .primaryUi01

        if let code = promoCode, code.count > 0 {
            if SyncManager.isUserLoggedIn() {
                redeemCode()
            } else {
                ValidatePromoCodeTask.validatePromoCode(promoCode: code, completion: { isValid, successMessage, error in
                    self.serverMessage = error?.localizedDescription ?? successMessage
                    if isValid {
                        self.processValidCode()
                    } else {
                        self.promoStatus = .codeExpired
                    }
                })
            }
        } else {
            if SyncManager.isUserLoggedIn(), SubscriptionHelper.hasActiveSubscription() {
                promoStatus = .existingPlusUser
            } else {
                promoStatus = .codeInvalid
            }
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped))
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        userLoginNotification = NotificationCenter.default.addObserver(forName: .userLoginDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.userDidSignIn = SyncManager.isUserLoggedIn()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if userDidSignIn {
            showAnimatingActivityIndicator()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if userDidSignIn {
            redeemAfterSignIn()
            userDidSignIn = false
        }
        updateDisplayMessage()
    }

    private func updateDisplayMessage() {
        DispatchQueue.main.async { () in

            switch self.promoStatus {
            case .validating:
                self.showAnimatingActivityIndicator()
            case .existingPlusUser:
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.titleLabel.isHidden = false
                self.titleLabel.text = L10n.plusErrorAlreadyRegistered
                self.descriptionLabel.isHidden = false
                self.descriptionLabel.text = L10n.plusErrorAlreadyRegisteredDetails
                self.centreImageView.isHidden = false
                self.centreImageView.imageNameFunc = AppTheme.setupNewAccountGoldImageName
                self.upgradeToPlusButton.isHidden = true
                self.signUpNoPromoButton.isHidden = true
                self.createAccountWithPromoButton.isHidden = true
                self.signInWithPromoButton.isHidden = true
                self.doneButton.isHidden = false
                self.buttonContainerView.isHidden = false
            case .codeExpired:
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.setNavigationTitleToLogo()
                self.titleLabel.isHidden = false
                self.titleLabel.text = L10n.plusPromotionExpired
                if self.serverMessage != nil {
                    self.descriptionLabel.isHidden = false
                    self.descriptionLabel.text = self.serverMessage
                }
                self.secondDescriptionLabel.isHidden = false
                self.secondDescriptionLabel.text = L10n.plusPromotionExpiredNudge
                self.centreImageView.isHidden = false
                self.centreImageView.imageNameFunc = AppTheme.promoErrorImageName
                self.createAccountWithPromoButton.isHidden = true
                self.signInWithPromoButton.isHidden = true
                self.upgradeToPlusButton.isHidden = true
                self.signUpNoPromoButton.isHidden = true

                if SyncManager.isUserLoggedIn() {
                    self.upgradeToPlusButton.isHidden = false
                } else {
                    self.signUpNoPromoButton.isHidden = false
                }
                self.buttonContainerView.isHidden = false
            case .codeInvalid:
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.setNavigationTitleToLogo()
                self.titleLabel.isHidden = false
                self.titleLabel.text = L10n.plusPromotionExpired
                self.descriptionLabel.text = self.serverMessage
                self.secondDescriptionLabel.text = L10n.plusPromotionExpiredNudge
                self.centreImageView.isHidden = false
                self.centreImageView.imageNameFunc = AppTheme.promoErrorImageName
                self.doneButton.isHidden = false
                self.createAccountWithPromoButton.isHidden = true
                self.signInWithPromoButton.isHidden = true

                if SyncManager.isUserLoggedIn() {
                    self.upgradeToPlusButton.isHidden = false
                } else {
                    self.signUpNoPromoButton.isHidden = false
                }
                self.buttonContainerView.isHidden = false
                self.createAccountWithPromoButton.setTitle(L10n.next, for: .normal)
            case .codeReused:
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.setNavigationTitleToLogo()
                self.titleLabel.isHidden = false
                self.titleLabel.text = L10n.plusPromotionUsed
                self.descriptionLabel.isHidden = false
                self.descriptionLabel.text = self.serverMessage
                self.centreImageView.isHidden = false
                self.centreImageView.imageNameFunc = AppTheme.promoErrorImageName
                self.buttonContainerView.isHidden = false
            case .signIn:
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.setNavigationTitleToPlusLogo()
                self.titleLabel.isHidden = false
                self.titleLabel.text = " " + L10n.signInPrompt
                self.descriptionLabel.isHidden = false

                self.descriptionLabel.text = L10n.plusAccountRequiredPrompt
                self.secondDescriptionLabel.text = L10n.plusAccountRequiredPromptDetails
                self.secondDescriptionLabel.isHidden = false
                self.centreImageView.isHidden = false
                self.centreImageView.imageNameFunc = AppTheme.accountUpgradedImageName
                self.createAccountWithPromoButton.isHidden = false
                self.signInWithPromoButton.isHidden = true
                self.doneButton.isHidden = true
                self.buttonContainerView.isHidden = false
                self.createAccountWithPromoButton.setTitle(L10n.next, for: .normal)
            }
        }
    }

    private func processValidCode() {
        if SyncManager.isUserLoggedIn() {
            redeemCode()
        } else {
            promoStatus = .signIn
        }
    }

    private func redeemCode() { // called for signed in users only
        guard let promoCode = promoCode else {
            promoStatus = .codeInvalid
            return
        }
        ApiServerHandler.shared.redeemPromoCode(promoCode: promoCode, completion: { status, successMessage, error in

            self.serverMessage = error?.localizedDescription ?? successMessage
            if status == ServerConstants.HttpConstants.ok {
                self.codeRedeemed()
            } else if status == ServerConstants.HttpConstants.badRequest {
                self.promoStatus = .codeReused
            } else if status == ServerConstants.HttpConstants.conflict {
                self.promoStatus = .existingPlusUser
            } else if status == ServerConstants.HttpConstants.notFound {
                self.promoStatus = .codeExpired
            }
        })
    }

    private func codeRedeemed() {
        SubscriptionHelper.setSubscriptionGiftAcknowledgement(true)
        ApiServerHandler.shared.retrieveSubscriptionStatus()
        Settings.setPromotionFinishedAcknowledged(false)
        delegate?.promotionRedeemed(message: serverMessage ?? "")

        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: true, completion: completion)

        if let userLoginNotification {
            NotificationCenter.default.removeObserver(userLoginNotification)
        }
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func createAccountTapped(_ sender: Any) {
        let controller = OnboardingFlow.shared.begin(flow: .promoCode, in: navigationController)
        navigationController?.pushViewController(controller, animated: true)
    }

    @IBAction func signInWithValidPromoTapped(_ sender: Any) {
        let controller = OnboardingFlow.shared.begin(flow: .promoCode, in: navigationController)
        navigationController?.pushViewController(controller, animated: true)
    }

    @IBAction func upgradeToPlusTapped(_ sender: Any) {
        dismiss(animated: true) {
            guard let controller = SceneHelper.rootViewController() else { return }
            NavigationManager.sharedManager.showUpsellView(from: controller, source: .promoCode)
        }
    }

    @IBAction func signUpNoPromoTapped(_ sender: Any) {
        dismiss(animated: true) {
            NavigationManager.sharedManager.navigateTo(NavigationManager.onboardingFlow, data: ["flow": OnboardingFlow.Flow.promoCode])
        }
    }

    // MARK: - Private helpers

    private func showAnimatingActivityIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        titleLabel.isHidden = true
        descriptionLabel.isHidden = true
        secondDescriptionLabel.isHidden = true
        centreImageView.isHidden = true
        buttonContainerView.isHidden = true
    }

    private func setNavigationTitleToLogo() {
        let logoImageView = ThemeableImageView(frame: CGRect(x: 0, y: 0, width: 170, height: 34))
        logoImageView.imageNameFunc = AppTheme.pcLogoHorizontalImageName
        logoImageView.contentMode = .scaleAspectFill
        navigationItem.titleView = logoImageView
    }

    private func setNavigationTitleToPlusLogo() {
        let logoImageView = ThemeableImageView(frame: CGRect(x: 0, y: 0, width: 240, height: 34))
        logoImageView.imageNameFunc = AppTheme.pcPlusLogoHorizontalImageName
        logoImageView.contentMode = .scaleAspectFill
        navigationItem.titleView = logoImageView
    }

    // MARK: - SyncSigninDelegate

    func signingProcessCompleted() {
        navigationController?.popToRootViewController(animated: true)
        userDidSignIn = true
    }

    // MARK: - AccountUpdatedDelegate

    func accountUpdatedAcknowledged() {
        navigationController?.popToRootViewController(animated: true)
        userDidSignIn = true
    }

    private func redeemAfterSignIn() {
        if promoStatus == .codeInvalid || promoStatus == .codeExpired || promoStatus == .codeReused {
            dismiss(animated: true, completion: nil)
        } else {
            promoStatus = .validating
            redeemCode()
        }
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }

    // MARK: - Status bar

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }
}
