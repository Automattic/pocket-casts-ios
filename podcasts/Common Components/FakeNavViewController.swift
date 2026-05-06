import PocketCastsUtils
import UIKit

class FakeNavViewController: PCViewController, UIScrollViewDelegate {
    private static let navBarBaseHeight: CGFloat = 45

    /// `true` when the screen is using the legacy fake navigation bar, `false` when it's relying on the
    /// system navigation bar (e.g. under Liquid Glass). Subclasses can branch on this to skip nav-bar
    /// hiding tricks they did to make room for the fake bar.
    var isUsingFakeNavBar: Bool { !LiquidGlass.isEnabled }

    private var navBar: LegacyFakeNavigationBar?
    private var customTitleLabel: UILabel?

    private lazy var placeholderNavView = UIView()
    private lazy var placeholderBackButton = UIButton()

    var fakeNavView: UIView { navBar ?? placeholderNavView }
    var backBtn: UIButton { navBar?.backButton ?? placeholderBackButton }
    var rightActionButtons: [UIButton] { navBar?.rightActionButtons ?? [] }

    private var navigationTitleSetOnScroll = false

    var navTitle: String?
    var scrollPointToChangeTitle: CGFloat = 0 {
        didSet {
            navigationTitleSetOnScroll = true
        }
    }

    enum NavDisplayMode {
        case navController, card
    }

    var showNavBarOnHide = true

    var displayMode = NavDisplayMode.navController
    var closeTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        if !isUsingFakeNavBar {
            useTransparentNavigationBarAppearance = true
            if displayMode == .card {
                navigationItem.leftBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .close,
                    target: self,
                    action: #selector(handleCloseTapped)
                )
            }
            configureCustomTitleView()
        } else {
            configureLegacyFakeNavBar()
        }
    }

    private func configureCustomTitleView() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.textColor = AppTheme.navBarTitleColor()
        label.alpha = 0
        navigationItem.titleView = label
        customTitleLabel = label
    }

    private func configureLegacyFakeNavBar() {
        let navBar = LegacyFakeNavigationBar(displayMode: displayMode)
        navBar.onCloseTapped = { [weak self] in
            self?.closeTapped?()
        }
        view.addSubview(navBar)
        NSLayoutConstraint.activate([
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        self.navBar = navBar
    }

    @objc private func handleCloseTapped() {
        closeTapped?()
    }

    private var haveHiddenOnce = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let navBar else {
            if let customTitleLabel {
                customTitleLabel.text = navTitle
                customTitleLabel.sizeToFit()
                if !navigationTitleSetOnScroll {
                    customTitleLabel.alpha = 1
                }
            }
            return
        }

        navigationController?.setNavigationBarHidden(true, animated: !haveHiddenOnce)
        haveHiddenOnce = true

        if !navigationTitleSetOnScroll { navBar.title = navTitle }
    }

    override func addChild(_ childController: UIViewController) {
        super.addChild(childController)

        guard isUsingFakeNavBar else { return }

        /// Hide the child nav bar on the next run loop since this doesn't have any effect if called immediately
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            childController.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isUsingFakeNavBar else { return }

        if displayMode == .navController, showNavBarOnHide {
            if let navController = navigationController {
                navController.setNavigationBarHidden(false, animated: true)
            } else {
                // there's a case when iOS pops a tab that it takes away our navigationController earlier than normal, handle that here
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.unhideNavBarRequested)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let navBar, let window = view.window {
            let statusBarHeight = displayMode == .card ? 9 : UIUtil.statusBarHeight(in: window)
            navBar.height = FakeNavViewController.navBarBaseHeight + statusBarHeight
        }
    }

    func navBarHeight(window: UIWindow) -> CGFloat {
        guard let navBar else { return 0 }
        return navBar.height - window.safeAreaInsets.top
    }

    func addGoogleCastBtn() {
        guard let navBar else {
            // PCViewController owns `navigationItem.rightBarButtonItems` and rebuilds it from
            // `supportsGoogleCast` + `googleCastBtn` + `extraRightButtons` in `refreshRightButtons()`.
            // Its viewDidLoad has already run, so set `supportsGoogleCast` and seed `googleCastBtn`
            // ourselves before triggering a refresh.
            return
        }

        let button = PCGoogleCastButton(frame: CGRect(x: 320, y: 21, width: 44, height: 44))
        button.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        navBar.addRightActionButton(button)
    }

    @discardableResult func addRightAction(image: UIImage?, accessibilityLabel: String, action: Selector) -> UIButton {
        let button = UIButton(frame: CGRect(x: 320, y: 21, width: 44, height: 44))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = accessibilityLabel
        if let navBar {
            navBar.addRightActionButton(button)
        } else {
            // Use a standard system bar button item; appending to PCViewController's
            button.tintColor = UIColor.label
            extraRightButtons.append(UIBarButtonItem(customView: button))
        }

        return button
    }

    /// Removes all the right button actions from the view
    func removeAllButtons() {
        if let navBar {
            navBar.removeAllRightActionButtons()
        } else {
            extraRightButtons = []
        }
    }

    func updateNavColors(bgColor: UIColor, titleColor: UIColor, buttonColor: UIColor, buttonBackgroundColor: UIColor) {
        navBar?.updateColors(background: bgColor, title: titleColor, button: buttonColor, buttonBackground: buttonBackgroundColor)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let navBar, navigationTitleSetOnScroll {
            navBar.updateForScroll(offset: scrollView.contentOffset.y, threshold: scrollPointToChangeTitle, title: navTitle)
        } else if let customTitleLabel, navigationTitleSetOnScroll {
            updateCustomTitleForScroll(scrollView, label: customTitleLabel)
        }
        setShadowVisible(false)
    }

    private func updateCustomTitleForScroll(_ scrollView: UIScrollView, label: UILabel) {
        if label.text != navTitle {
            label.text = navTitle
            label.sizeToFit()
        }
        let scrolledToY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let targetAlpha: CGFloat = scrolledToY > scrollPointToChangeTitle ? 1 : 0
        guard label.alpha != targetAlpha else { return }
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            label.alpha = targetAlpha
        }
    }

    func setShadowVisible(_ visible: Bool) {
        navBar?.setShadowVisible(visible)
    }

    func updateNavigationBar(position: CGFloat) {
        navBar?.snapToScroll(offset: position, threshold: scrollPointToChangeTitle)
    }
}

private final class LegacyFakeNavigationBar: UIView {
    let backButton: UIButton
    private(set) var rightActionButtons: [UIButton] = []

    var onCloseTapped: (() -> Void)?

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var height: CGFloat {
        get { heightConstraint.constant }
        set {
            if heightConstraint.constant != newValue {
                heightConstraint.constant = newValue
            }
        }
    }

    private let titleLabel = UILabel()
    private let displayMode: FakeNavViewController.NavDisplayMode
    private var heightConstraint: NSLayoutConstraint!
    private var titleMaxWidthConstraint: NSLayoutConstraint!
    private var backButtonLeadingConstraint: NSLayoutConstraint!

    init(displayMode: FakeNavViewController.NavDisplayMode) {
        self.displayMode = displayMode
        self.backButton = UIButton(frame: CGRect(x: 0, y: 21, width: 40, height: 44))
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowOffset = CGSize(width: 0, height: 2)

        heightConstraint = heightAnchor.constraint(equalToConstant: 65)
        heightConstraint.isActive = true

        backButton.isPointerInteractionEnabled = true
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        let backImage = displayMode == .navController ? UIImage(systemName: "chevron.backward") : UIImage(named: "episode-close")
        backButton.setImage(backImage, for: .normal)
        backButton.accessibilityLabel = L10n.close
        backButton.accessibilityIdentifier = "Close"
        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        var margin: CGFloat = 0
        var buttonSize: CGFloat = 44
        if displayMode == .navController {
            buttonSize = 32
            backButton.layer.cornerRadius = buttonSize / 2
            backButton.layer.masksToBounds = true
            margin = 16
        }
        let leadingOffset: CGFloat = displayMode == .navController ? margin : 6
        backButtonLeadingConstraint = backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingOffset)
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: buttonSize),
            backButton.heightAnchor.constraint(equalToConstant: buttonSize),
            backButtonLeadingConstraint,
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleMaxWidthConstraint = titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleMaxWidthConstraint,
            bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // we need to allow enough room to show 2 buttons on the right
        let buttonsWidth = CGFloat(220)
        let maxTitleWidth = bounds.width - buttonsWidth
        if titleMaxWidthConstraint.constant != maxTitleWidth {
            titleMaxWidthConstraint.constant = maxTitleWidth
        }
    }

    func addRightActionButton(_ button: UIButton) {
        button.isPointerInteractionEnabled = true
        addSubview(button)
        var buttonSize: CGFloat = 44
        var imageSize: CGFloat = 24
        if displayMode == .navController {
            buttonSize = 32
            imageSize = 20
            button.imageView?.contentMode = .scaleAspectFit
            if let imageView = button.imageView {
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.frame = CGRect(x: 0, y: 0, width: imageSize, height: imageSize)
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: imageSize),
                    imageView.heightAnchor.constraint(equalToConstant: imageSize),
                ])
            }
            button.layer.cornerRadius = buttonSize / 2
            button.layer.masksToBounds = true
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        if rightActionButtons.isEmpty {
            // if there are no other buttons, anchor this one to the edge
            let margin: CGFloat = 16
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize),
                trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: margin),
                button.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            let previousButton = rightActionButtons.last!
            let margin: CGFloat = 8
            // otherwise anchor it to the previous button
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize),
                button.trailingAnchor.constraint(equalTo: previousButton.leadingAnchor, constant: -margin),
                button.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        rightActionButtons.append(button)
    }

    func removeAllRightActionButtons() {
        for button in rightActionButtons {
            button.removeFromSuperview()
        }
        rightActionButtons = []
    }

    func updateColors(background: UIColor, title titleColor: UIColor, button buttonColor: UIColor, buttonBackground buttonBackgroundColor: UIColor) {
        backgroundColor = background
        titleLabel.textColor = titleColor
        backButton.tintColor = buttonColor
        backButton.backgroundColor = buttonBackgroundColor
        for button in rightActionButtons {
            button.tintColor = buttonColor
            button.backgroundColor = buttonBackgroundColor
        }
    }

    func setShadowVisible(_ visible: Bool) {
        let opacity: Float = visible ? 0.2 : 0
        guard opacity != layer.shadowOpacity else { return }
        layer.shadowOpacity = opacity
    }

    /// Animates a title fade and chrome transition when the scroll position crosses the threshold.
    func updateForScroll(offset: CGFloat, threshold: CGFloat, title: String?) {
        let scrolledToY = offset + height
        if scrolledToY > threshold, self.title == nil {
            setTitleAnimated(title)
            setTransparent(false, animated: true)
        } else if scrolledToY < threshold, self.title != nil {
            setTitleAnimated(nil)
            setTransparent(true, animated: true)
        }
    }

    /// Snaps the chrome to match the given scroll position without animation; leaves the title alone.
    func snapToScroll(offset: CGFloat, threshold: CGFloat) {
        let scrolledToY = offset + height
        if scrolledToY > threshold {
            setTransparent(false, animated: false)
        } else if scrolledToY < threshold {
            setTransparent(true, animated: false)
        }
    }

    private func setTitleAnimated(_ newTitle: String?) {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = Constants.Animation.defaultAnimationTime
        fadeTextAnimation.type = CATransitionType.fade

        titleLabel.layer.add(fadeTextAnimation, forKey: "fadeText")
        layer.add(fadeTextAnimation, forKey: "fadeText")
        if newTitle == nil {
            applyTransparentChrome()
        } else {
            applyOpaqueChrome()
        }
        titleLabel.text = newTitle
    }

    private func setTransparent(_ transparent: Bool, animated: Bool) {
        if animated {
            let fadeAnimation = CATransition()
            fadeAnimation.duration = Constants.Animation.defaultAnimationTime
            fadeAnimation.type = CATransitionType.fade
            layer.add(fadeAnimation, forKey: "fadeBackgroundAnimation")
        }
        if transparent {
            applyTransparentChrome()
            backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
            backButtonLeadingConstraint.constant = 16
        } else {
            applyOpaqueChrome()
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            backButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(config), for: .normal)
            backButtonLeadingConstraint.constant = 6
        }
    }

    private func applyTransparentChrome() {
        backgroundColor = .clear
        applyButtonChrome(tintColor: .white, backgroundColor: .black.withAlphaComponent(0.35))
    }

    private func applyOpaqueChrome() {
        backgroundColor = ThemeColor.primaryUi01()
        titleLabel.textColor = AppTheme.mainTextColor()
        applyButtonChrome(tintColor: ThemeColor.primaryIcon01(), backgroundColor: .clear)
    }

    private func applyButtonChrome(tintColor: UIColor, backgroundColor: UIColor) {
        backButton.tintColor = tintColor
        backButton.backgroundColor = backgroundColor
        for button in rightActionButtons {
            button.tintColor = tintColor
            button.backgroundColor = backgroundColor
        }
    }

    @objc private func backButtonTapped() {
        onCloseTapped?()
    }
}
