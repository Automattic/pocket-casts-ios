import PocketCastsServer
import UIKit

class UpgradeRequiredViewController: PCViewController {
    @IBOutlet var upgradeButton: ThemeableRoundedButton! {
        didSet {
            upgradeButton.setTitle(L10n.plusMarketingUpgradeButton, for: .normal)
        }
    }

    @IBOutlet var featureInfoView: PlusFeaturesView!
    @IBOutlet var logoImageView: ThemeableImageView! {
        didSet {
            logoImageView.imageNameFunc = AppTheme.pcPlusLogoVerticalImageName
        }
    }
    
    @IBOutlet var verticalLogo: UIImageView! {
        didSet {
            verticalLogo.image = Theme.isDarkTheme() ? UIImage(named: "verticalLogoDark") : UIImage(named: "verticalLogo")
        }
    }
    
    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.style = .primaryText01
            infoLabel.text = L10n.plusRequiredFeature
        }
    }
    
    @IBOutlet var priceLabel: ThemeableLabel! {
        didSet {
            priceLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var noThanksButton: ThemeableRoundedButton! {
        didSet {
            noThanksButton.shouldFill = false
            noThanksButton.setTitle(L10n.settingsGeneralNoThanks, for: .normal)
        }
    }
    
    var upgradeRootViewController: UIViewController
    
    init(upgradeRootViewController: UIViewController) {
        self.upgradeRootViewController = upgradeRootViewController
        super.init(nibName: "UpgradeRequiredViewController", bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.pocketCastsPlus
        
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)
        
        let monthlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)
        if monthlyPrice.count > 0 {
            priceLabel.text = L10n.plusPricePerMonth(monthlyPrice)
        }
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneCicked))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }
    
    @IBOutlet var learnMoreButton: ThemeableRoundedButton! {
        didSet {
            learnMoreButton.textStyle = .primaryInteractive01
            learnMoreButton.buttonStyle = .primaryUi01
            learnMoreButton.setTitle(L10n.plusMarketingLearnMoreButton, for: .normal)
        }
    }
    
    @IBAction func learnMoreClicked(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
    }
    
    @IBAction func doneCicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func upgradeClicked(_ sender: Any) {
        let upgradeRootVC = upgradeRootViewController
        dismiss(animated: true, completion: {
            if SyncManager.isUserLoggedIn() {
                let newSubscription = NewSubscription(isNewAccount: false, iap_identifier: "")
                let termsVC = TermsViewController(newSubscription: newSubscription)
                upgradeRootVC.present(SJUIUtils.popupNavController(for: termsVC), animated: true, completion: nil)
            }
            else {
                let profileIntroController = ProfileIntroViewController()
                upgradeRootVC.present(SJUIUtils.popupNavController(for: profileIntroController), animated: true, completion: nil)
            }
        })
    }
    
    @objc func iapProductsUpdated() {
        let monthlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)
        if monthlyPrice.count > 0 {
            priceLabel.text = L10n.plusPricePerMonth(monthlyPrice)
        }
    }
    
    // MARK: - Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
