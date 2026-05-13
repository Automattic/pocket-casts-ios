import PocketCastsUtils
import UIKit

class FakeNavViewController: PCViewController, UIScrollViewDelegate {
    private static let navBarBaseHeight: CGFloat = 45

    private var navBar: LegacyFakeNavigationBar!

    var fakeNavView: UIView { navBar }
    var backBtn: UIButton { navBar.backButton }
    var rightActionButtons: [UIButton] { navBar.rightActionButtons }

    private var navigationTitleSetOnScroll = false

    var navTitle: String?
    var scrollPointToChangeTitle: CGFloat = 0 {
        didSet {
            navigationTitleSetOnScroll = true
        }
    }

    var closeTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let navBar = LegacyFakeNavigationBar()
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

    private var haveHiddenOnce = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: !haveHiddenOnce)
        haveHiddenOnce = true

        if !navigationTitleSetOnScroll { navBar.title = navTitle }
    }

    override func addChild(_ childController: UIViewController) {
        super.addChild(childController)

        /// Hide the child nav bar on the next run loop since this doesn't have any effect if called immediately
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            childController.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if view.window != nil {
            navBar.height = FakeNavViewController.navBarBaseHeight + 9
        }
    }

    func navBarHeight(window: UIWindow) -> CGFloat {
        navBar.height - window.safeAreaInsets.top
    }

    func addGoogleCastBtn() {
        let button = PCGoogleCastButton(frame: CGRect(x: 320, y: 21, width: 44, height: 44))
        button.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        navBar.addRightActionButton(button)
    }

    @discardableResult func addRightAction(image: UIImage?, accessibilityLabel: String, action: Selector) -> UIButton {
        let button = UIButton(frame: CGRect(x: 320, y: 21, width: 44, height: 44))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = accessibilityLabel
        navBar.addRightActionButton(button)

        return button
    }

    /// Removes all the right button actions from the view
    func removeAllButtons() {
        navBar.removeAllRightActionButtons()
    }

    func updateNavColors(bgColor: UIColor, titleColor: UIColor, buttonColor: UIColor, buttonBackgroundColor: UIColor) {
        navBar.updateColors(background: bgColor, title: titleColor, button: buttonColor, buttonBackground: buttonBackgroundColor)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if navigationTitleSetOnScroll {
            navBar.updateForScroll(offset: scrollView.contentOffset.y, threshold: scrollPointToChangeTitle, title: navTitle)
        }
        setShadowVisible(false)
    }

    func setShadowVisible(_ visible: Bool) {
        navBar.setShadowVisible(visible)
    }

    func updateNavigationBar(position: CGFloat) {
        navBar.snapToScroll(offset: position, threshold: scrollPointToChangeTitle)
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
    private var heightConstraint: NSLayoutConstraint!
    private var titleMaxWidthConstraint: NSLayoutConstraint!
    private var backButtonLeadingConstraint: NSLayoutConstraint!

    init() {
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
        backButton.setImage(UIImage(named: "episode-close"), for: .normal)
        backButton.accessibilityLabel = L10n.close
        backButton.accessibilityIdentifier = "Close"
        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonSize: CGFloat = 44
        backButtonLeadingConstraint = backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6)
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
        let buttonSize: CGFloat = 44
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
