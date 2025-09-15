import PocketCastsUtils
import UIKit

class FakeNavViewController: PCViewController, UIScrollViewDelegate {
    private static let navBarBaseHeight: CGFloat = 45

    private(set) var fakeNavView: UIView!
    private(set) var backBtn: UIButton!
    private(set) var rightActionButtons = [UIButton]()
    private var fakeNavHeight: NSLayoutConstraint!
    private var fakeNavTitle: UILabel!

    private var navigationTitleSetOnScroll = false

    private var navTitleMaxWidth: NSLayoutConstraint!

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

    private var backBtnLeadingConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        fakeNavView = UIView()
        view.addSubview(fakeNavView)
        fakeNavView.translatesAutoresizingMaskIntoConstraints = false
        fakeNavHeight = fakeNavView.heightAnchor.constraint(equalToConstant: 65)
        NSLayoutConstraint.activate([
            fakeNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fakeNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fakeNavView.topAnchor.constraint(equalTo: view.topAnchor),
            fakeNavHeight
        ])
        fakeNavView.layer.shadowOffset = CGSize(width: 0, height: 2)

        backBtn = UIButton(frame: CGRect(x: 0, y: 21, width: 40, height: 44))
        backBtn.isPointerInteractionEnabled = true
        backBtn.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        let backImage = displayMode == .navController ? UIImage(systemName: "chevron.backward") : UIImage(named: "episode-close")
        backBtn.setImage(backImage, for: .normal)
        backBtn.accessibilityLabel = L10n.close
        backBtn.accessibilityIdentifier = "Close"
        fakeNavView.addSubview(backBtn)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        var margin: CGFloat = 0
        var buttonSize: CGFloat = 44
        if displayMode == .navController {
            buttonSize = 32
            backBtn.layer.cornerRadius = buttonSize / 2
            backBtn.layer.masksToBounds = true
            margin = 16
        }
        let leadingOffset: CGFloat = displayMode == .navController ? margin : 6
        let backBtnLeadingConstraint = backBtn.leadingAnchor.constraint(equalTo: fakeNavView.leadingAnchor, constant: leadingOffset)
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(equalToConstant: buttonSize),
            backBtn.heightAnchor.constraint(equalToConstant: buttonSize),
            backBtnLeadingConstraint,
            backBtn.bottomAnchor.constraint(equalTo: fakeNavView.bottomAnchor)
        ])
        self.backBtnLeadingConstraint = backBtnLeadingConstraint
        fakeNavTitle = UILabel()
        fakeNavTitle.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        fakeNavTitle.textAlignment = .center
        fakeNavView.addSubview(fakeNavTitle)
        fakeNavTitle.translatesAutoresizingMaskIntoConstraints = false
        navTitleMaxWidth = fakeNavTitle.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
        NSLayoutConstraint.activate([
            fakeNavTitle.centerXAnchor.constraint(equalTo: fakeNavView.centerXAnchor),
            navTitleMaxWidth!,
            fakeNavView.bottomAnchor.constraint(equalTo: fakeNavTitle.bottomAnchor, constant: 12)
        ])
    }

    private var haveHiddenOnce = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: !haveHiddenOnce)
        haveHiddenOnce = true

        if !navigationTitleSetOnScroll { fakeNavTitle.text = navTitle }
    }

    override func addChild(_ childController: UIViewController) {
        super.addChild(childController)

        /// Hide the child nav bar on the next run loop since this doesn't have any effect if called immediately
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            childController.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

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

        if let window = view.window {
            let statusBarHeight = displayMode == .card ? 9 : UIUtil.statusBarHeight(in: window)
            let requiredTopHeight = FakeNavViewController.navBarBaseHeight + statusBarHeight
            if fakeNavHeight.constant != requiredTopHeight {
                fakeNavHeight.constant = requiredTopHeight
            }
        }

        // we need to allow enough room to show 2 buttons on the right
        var buttonsWidth = CGFloat(220)

        let maxTitleWidth = fakeNavView.bounds.width - buttonsWidth
        if navTitleMaxWidth.constant != maxTitleWidth {
            navTitleMaxWidth.constant = maxTitleWidth
        }
    }

    func navBarHeight(window: UIWindow) -> CGFloat {
        fakeNavHeight.constant - window.safeAreaInsets.top
    }

    func addGoogleCastBtn() {
        let button = PCGoogleCastButton(frame: CGRect(x: 320, y: 21, width: 44, height: 44))
        button.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        addButton(button)
    }

    @discardableResult func addRightAction(image: UIImage?, accessibilityLabel: String, action: Selector) -> UIButton {
        let button = UIButton(frame: CGRect(x: 320, y: 21, width: 44, height: 44))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = accessibilityLabel
        addButton(button)

        return button
    }

    private func addButton(_ button: UIButton) {
        button.isPointerInteractionEnabled = true
        fakeNavView.addSubview(button)
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
        if rightActionButtons.count == 0 {
            // if there are no other buttons, anchor this one to the edge
            let margin: CGFloat = 16
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize),
                fakeNavView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: margin),
                button.bottomAnchor.constraint(equalTo: fakeNavView.bottomAnchor)
            ])
        } else {
            let previousButton = rightActionButtons.last!
            let margin: CGFloat = 8
            // otherwise anchor it to the previous button
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize),
                button.trailingAnchor.constraint(equalTo: previousButton.leadingAnchor, constant: -margin),
                button.bottomAnchor.constraint(equalTo: fakeNavView.bottomAnchor)
            ])
        }
        rightActionButtons.append(button)
    }

    /// Removes all the right button actions from the view
    func removeAllButtons() {
        for button in rightActionButtons {
            button.removeFromSuperview()
        }

        rightActionButtons = []
    }

    func updateNavColors(bgColor: UIColor, titleColor: UIColor, buttonColor: UIColor, buttonBackgroundColor: UIColor) {
        fakeNavView.backgroundColor = bgColor
        fakeNavTitle.textColor = titleColor
        backBtn.tintColor = buttonColor
        backBtn.backgroundColor = buttonBackgroundColor
        for button in rightActionButtons {
            button.tintColor = buttonColor
            button.backgroundColor = buttonBackgroundColor
        }
    }

    @objc private func closeBtnTapped() {
        closeTapped?()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrolledToY = scrollView.contentOffset.y + fakeNavHeight.constant
        if navigationTitleSetOnScroll {
            if scrolledToY > scrollPointToChangeTitle, fakeNavTitle.text == nil {
                changeTitleAnimated(navTitle)
                updateNavigationBar(transparent: false, animated: true)
            } else if scrolledToY < scrollPointToChangeTitle, fakeNavTitle.text != nil {
                changeTitleAnimated(nil)
                updateNavigationBar(transparent: true, animated: true)
            }
        }
        setShadowVisible(false)
    }

    func setShadowVisible(_ visible: Bool) {
        let opacity: Float = visible ? 0.2 : 0
        guard opacity != fakeNavView.layer.shadowOpacity else { return }

        fakeNavView.layer.shadowOpacity = opacity
    }

    func updateNavigationBar(position: CGFloat) {
        let scrolledToY = position + fakeNavHeight.constant
        if scrolledToY > scrollPointToChangeTitle {
            updateNavigationBar(transparent: false, animated: false)
        } else if scrolledToY < scrollPointToChangeTitle {
            updateNavigationBar(transparent: true, animated: false)
        }
    }

    private func updateNavigationBar(transparent: Bool, animated: Bool = true) {
        if animated {
            let fadeAnimation = CATransition()
            fadeAnimation.duration = Constants.Animation.defaultAnimationTime
            fadeAnimation.type = CATransitionType.fade
            fakeNavView.layer.add(fadeAnimation, forKey: "fadeBackgroundAnimation")
        }
        if transparent {
            fakeNavView.backgroundColor = .clear
            updateButtonsBackgroundColors(tintColor: .white, backgroundColor: .black.withAlphaComponent(0.35))
            backBtn.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
            backBtnLeadingConstraint?.constant = 16
        } else {
            fakeNavView.backgroundColor = ThemeColor.primaryUi01()
            fakeNavTitle.textColor = AppTheme.mainTextColor()
            updateButtonsBackgroundColors(tintColor: ThemeColor.primaryIcon01(), backgroundColor: .clear)
            let config = UIImage.SymbolConfiguration(textStyle: UIFont.TextStyle(rawValue: "UICTFontTextStyleEmphasizedBody"), scale: .large)
            backBtn.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(config), for: .normal)
            backBtnLeadingConstraint?.constant = 6
        }
    }

    private func changeTitleAnimated(_ newTitle: String?) {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = Constants.Animation.defaultAnimationTime
        fadeTextAnimation.type = CATransitionType.fade

        fakeNavTitle.layer.add(fadeTextAnimation, forKey: "fadeText")
        fakeNavView.layer.add(fadeTextAnimation, forKey: "fadeText")
        if newTitle == nil {
            fakeNavView.backgroundColor = .clear
            updateButtonsBackgroundColors(tintColor: .white, backgroundColor: .black.withAlphaComponent(0.35))
        } else {
            fakeNavView.backgroundColor = ThemeColor.primaryUi01()
            fakeNavTitle.textColor = AppTheme.mainTextColor()
            updateButtonsBackgroundColors(tintColor: ThemeColor.primaryIcon01(), backgroundColor: .clear)
        }
        fakeNavTitle.text = newTitle
    }

    private func updateButtonsBackgroundColors(tintColor: UIColor, backgroundColor: UIColor) {
        backBtn.tintColor = tintColor
        backBtn.backgroundColor = backgroundColor
        for button in rightActionButtons {
            button.tintColor = tintColor
            button.backgroundColor = backgroundColor
        }
    }
}
