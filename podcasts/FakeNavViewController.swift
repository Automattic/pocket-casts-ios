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
        let backImage = displayMode == .navController ? UIImage(named: "nav-back") : UIImage(named: "episode-close")
        backBtn.setImage(backImage, for: .normal)
        backBtn.accessibilityLabel = L10n.close
        backBtn.accessibilityIdentifier = "Close"
        fakeNavView.addSubview(backBtn)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        let leftOffset: CGFloat = displayMode == .navController ? 0 : 6
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.leadingAnchor.constraint(equalTo: fakeNavView.leadingAnchor, constant: leftOffset),
            backBtn.bottomAnchor.constraint(equalTo: fakeNavView.bottomAnchor)
        ])

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
        let maxTitleWidth = fakeNavView.bounds.width - 180
        if navTitleMaxWidth.constant != maxTitleWidth {
            navTitleMaxWidth.constant = maxTitleWidth
        }
    }

    func navBarHeight(window: UIWindow) -> CGFloat {
        fakeNavHeight.constant - UIUtil.statusBarHeight(in: window)
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

        button.translatesAutoresizingMaskIntoConstraints = false
        if rightActionButtons.count == 0 {
            // if there are no other buttons, anchor this one to the edge
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 44),
                button.heightAnchor.constraint(equalToConstant: 44),
                fakeNavView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 5),
                button.bottomAnchor.constraint(equalTo: fakeNavView.bottomAnchor)
            ])
        } else {
            let previousButton = rightActionButtons.last!
            // otherwise anchor it to the previous button
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 44),
                button.heightAnchor.constraint(equalToConstant: 44),
                button.trailingAnchor.constraint(equalTo: previousButton.leadingAnchor, constant: 0),
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

    func updateNavColors(bgColor: UIColor, titleColor: UIColor, buttonColor: UIColor) {
        fakeNavView.backgroundColor = bgColor
        fakeNavTitle.textColor = titleColor
        backBtn.tintColor = buttonColor
        for button in rightActionButtons {
            button.tintColor = buttonColor
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
            } else if scrolledToY < scrollPointToChangeTitle, fakeNavTitle.text != nil {
                changeTitleAnimated(nil)
            }
        }

        setShadowVisible(scrolledToY > 9)
    }

    func setShadowVisible(_ visible: Bool) {
        let opacity: Float = visible ? 0.2 : 0
        guard opacity != fakeNavView.layer.shadowOpacity else { return }

        fakeNavView.layer.shadowOpacity = opacity
    }

    private func changeTitleAnimated(_ newTitle: String?) {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = Constants.Animation.defaultAnimationTime
        fadeTextAnimation.type = CATransitionType.fade
        fakeNavTitle.layer.add(fadeTextAnimation, forKey: "fadeText")

        fakeNavTitle.text = newTitle
    }
}
