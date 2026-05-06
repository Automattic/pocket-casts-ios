import UIKit

class PCViewController: SimpleNotificationsViewController {
    var supportsGoogleCast = false
    var largeTitleFont = UIFont.systemFont(ofSize: 31, weight: .bold)

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

    var useTransparentNavigationBarAppearance = false {
        didSet {
            setupNavBar(animated: false)
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
            castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
            if useTransparentNavigationBarAppearance {
                FakeNavBarButton.applyStyle(to: castButton)
            } else {
                castButton.tintColor = navIconsColor ?? AppTheme.navBarIconsColor()
            }
            googleCastBtn = UIBarButtonItem(customView: castButton)

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

        if let title, !title.isEmpty {
            setupNavBar(animated: animated)
        }
        refreshRightButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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
            if let customRightBtn {
                buttons.append(customRightBtn)
            }
            if let googleCastBtn, supportsGoogleCast {
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

    func createStandardCloseButton(imageName: String) -> UIBarButtonItem {
        let closeButton = UIBarButtonItem(image: UIImage(named: imageName), style: .plain, target: nil, action: nil)
        return closeButton
    }

    @objc private func themeDidChange() {
        setupNavBar(animated: false)
        handleThemeChanged()
    }

    private func setupNavBar(animated: Bool) {
        guard let navController = navigationController else { return }

        guard !useTransparentNavigationBarAppearance else {
            configureTransparentAppearance()
            return
        }

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
            NSAttributedString.Key.font: largeTitleFont
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

    private func configureTransparentAppearance() {
        setTransparentNavBarScrolled(false)
    }

    /// Toggles the navigation bar between its at-edge (transparent) and scrolled (blurred) styles,
    /// and forwards the new state to any `FakeNavBarStylable` bar buttons so their tint and background
    /// crossfade in step. Subclasses using `useTransparentNavigationBarAppearance` should call this
    /// from `scrollViewDidScroll` when the scroll position crosses their header threshold;
    /// UIKit animates the appearance swap. On iOS 26 the default Liquid Glass background adapts on
    /// its own, so the bar appearance change is a no-op there but the buttons still update.
    func setTransparentNavBarScrolled(_ scrolled: Bool) {
        guard let navigationBar = navigationController?.navigationBar else {
            return assertionFailure("navigationBar is missing")
        }
        let appearance = UINavigationBarAppearance()
        if #available(iOS 26, *) {
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithTransparentBackground()
            if scrolled {
                appearance.backgroundEffect = UIBlurEffect(style: .regular)
            }
        }
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance

        let allItems = ([navigationItem.leftBarButtonItem, customRightBtn, googleCastBtn].compactMap { $0 }) + extraRightButtons
        for item in allItems {
            (item.customView as? FakeNavBarStylable)?.setNavBarScrolled(scrolled, animated: true)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
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

    var insetAdjuster = InsetAdjuster()
}
