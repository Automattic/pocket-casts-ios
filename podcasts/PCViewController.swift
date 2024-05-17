import UIKit

class PCViewController: SimpleNotificationsViewController {
    var supportsGoogleCast = false

    var googleCastBtn: UIBarButtonItem?
    var customRightBtn: UIBarButtonItem? {
        didSet {
            refreshRightButtons()
        }
    }

    var extraRightButtons: [UIBarButtonItem] = [] {
        didSet {
            refreshRightButtons()
        }
    }

    private var navIconsColor: UIColor?
    private var navTitleColor: UIColor?
    private var navBgColor: UIColor?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav-back")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav-back")

        navigationItem.backButtonDisplayMode = .minimal

        if supportsGoogleCast {
            let castButton = PCGoogleCastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            castButton.tintColor = navIconsColor ?? AppTheme.navBarIconsColor()
            googleCastBtn = UIBarButtonItem(customView: castButton)
            castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)

            refreshRightButtons()
        } else if customRightBtn != nil || !extraRightButtons.isEmpty {
            refreshRightButtons()
        }
        setupNavBar(animated: false)

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc func castButtonTapped() {
        let castController = CastToViewController()
        let navController = SJUIUtils.navController(for: castController)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true, completion: nil)
    }

    deinit {
        navigationController?.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = title, title.count > 0 {
            setupNavBar(animated: animated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshRightButtons()

        if supportsGoogleCast {
            NotificationCenter.default.addObserver(self, selector: #selector(refreshRightButtons), name: Constants.Notifications.googleCastStatusChanged, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appWasBackgrounded), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if customRightBtn != nil || supportsGoogleCast {
            navigationItem.rightBarButtonItems = nil
            navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationController?.delegate = nil

        if supportsGoogleCast {
            NotificationCenter.default.removeObserver(self, name: Constants.Notifications.googleCastStatusChanged, object: nil)
        }

        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func refreshRightButtons() {
        if supportsGoogleCast || !extraRightButtons.isEmpty {
            var buttons = [UIBarButtonItem]()
            if let customRightBtn = customRightBtn {
                buttons.append(customRightBtn)
            }
            if let googleCastBtn = googleCastBtn, supportsGoogleCast {
                buttons.append(googleCastBtn)
            }
            buttons.append(contentsOf: extraRightButtons)
            navigationItem.rightBarButtonItems = buttons
        } else {
            navigationItem.rightBarButtonItems = nil
            navigationItem.rightBarButtonItem = customRightBtn
        }
    }

    func changeNavTint(titleColor: UIColor?, iconsColor: UIColor?, backgroundColor: UIColor? = nil) {
        navTitleColor = titleColor
        navIconsColor = iconsColor
        navBgColor = backgroundColor

        setupNavBar(animated: false)
    }

    func createStandardCloseButton(imageName: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: imageName)
        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 22)
        config.titlePadding = 0

        let closeButton = UIButton(configuration: config)
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        return closeButton
    }

    @objc private func themeDidChange() {
        setupNavBar(animated: false)
        handleThemeChanged()
    }

    private func setupNavBar(animated: Bool) {
        guard let navController = navigationController else { return }

        let navigationBar = navController.navigationBar
        let titleColor = navTitleColor ?? AppTheme.navBarTitleColor()
        let iconsColor = navIconsColor ?? AppTheme.navBarIconsColor()
        let backgroundColor = navBgColor ?? ThemeColor.secondaryUi01()

        navigationBar.backIndicatorImage = UIImage(named: "nav-back")?.tintedImage(iconsColor)
        navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav-back")?.tintedImage(iconsColor)
        googleCastBtn?.customView?.tintColor = iconsColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: titleColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 31, weight: .bold)
        ]
        appearance.shadowColor = nil

        if animated {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                navigationBar.standardAppearance = appearance
                navigationBar.scrollEdgeAppearance = appearance
                navigationBar.tintColor = iconsColor
            })
        } else {
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.tintColor = iconsColor
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        appDelegate()?.miniPlayer()?.playerOpenState == .open
    }

    @objc private func appWasBackgrounded() {
        handleAppDidEnterBackground()
    }

    @objc private func appWillBecomeActive() {
        handleAppWillBecomeActive()
    }

    func handleAppDidEnterBackground() {}
    func handleAppWillBecomeActive() {}
    func handleThemeChanged() {}

    var insetAdjuster = MiniPlayerInsetAdjuster()
}

class MiniPlayerInsetAdjuster {

    init() {

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    var isMultiSelectEnabled: Bool = false {
        didSet {
            miniPlayerVisibilityDidChange()
        }
    }

    private var scrollViewAdjustableToMiniPlayer: UIScrollView?

    func setupInsetAdjustmentsForMiniPlayer(scrollView: UIScrollView) {
        guard scrollViewAdjustableToMiniPlayer == nil else {
            // This method should only be called once for each ViewController
            return
        }
        scrollViewAdjustableToMiniPlayer = scrollView

        NotificationCenter.default.addObserver(self, selector: #selector(miniPlayerVisibilityDidChange), name: Constants.Notifications.miniPlayerDidDisappear, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(miniPlayerVisibilityDidChange), name: Constants.Notifications.miniPlayerDidAppear, object: nil)

        miniPlayerVisibilityDidChange()
    }

    @objc func miniPlayerVisibilityDidChange() {
        guard let scrollView = scrollViewAdjustableToMiniPlayer else {
            return
        }
        scrollView.updateContentInset(multiSelectEnabled: self.isMultiSelectEnabled)
    }
}
