import UIKit

class OptionsPickerRootController: UIViewController, UIGestureRecognizerDelegate {

    struct Colors {
        let title: UIColor
        let background: UIColor

        init(title: UIColor, background: UIColor) {
            self.title = title
            self.background = background
        }

        init(theme: Theme.ThemeType) {
            title = ThemeColor.support01(for: theme)
            background = AppTheme.optionPickerBackgroundColor(for: theme)
        }
    }

    @objc var overrideStatusBarStyle = AppTheme.defaultStatusBarStyle()

    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var stackBgView: UIView!

    private let buttonCornerRadius: CGFloat = 8
    private var actionHeight: CGFloat = 72
    private let layoutHorizontalMargin = CGFloat(20)
    private var actionsAdded = 0

    private var themeOverride: Theme.ThemeType?
    private var iconTintStyle: ThemeStyle = .primaryIcon01
    // this is not a weak var on purpose, nothing retains an OptionsPicker so we will until it dismisses
    var delegate: OptionsPicker?

    var portraitOnly = true

    private var scrollViewBottomAnchor: NSLayoutConstraint?
    private var scrollViewTopAnchor: NSLayoutConstraint?
    private var scrollViewHeightConstraint: NSLayoutConstraint?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        overrideStatusBarStyle
    }

    func setup(title: String?, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle, colors: Colors? = nil) {
        let colors = colors ?? Colors(theme: themeOverride ?? Theme.sharedTheme.activeTheme)

        view.clipsToBounds = true
        view.layer.cornerRadius = 6
        self.themeOverride = themeOverride
        self.iconTintStyle = iconTintStyle

        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.layer.cornerRadius = 6
        scrollView.clipsToBounds = true
        view.addSubview(scrollView)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackBgView = UIView()
        stackView.insertSubview(stackBgView, at: 0)
        stackBgView.anchorToAllSidesOf(view: stackView)

        stackBgView.backgroundColor = colors.background

        scrollView.addSubview(stackView)

        stackBgView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        stackBgView.layer.shadowOffset = CGSize(width: 0, height: -1)
        stackBgView.layer.shadowOpacity = 0.2
        stackBgView.layer.shadowRadius = 10
        stackBgView.layer.cornerRadius = 6
        stackBgView.layer.shadowPath = UIBezierPath(rect: stackBgView.layer.bounds).cgPath

        // Stack view fills the scroll view's content area at full width
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // The scroll view height matches its content height when possible,
        // but is capped at the available vertical space so it never overflows.
        let maxHeightConstraint = scrollView.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, constant: -100)
        maxHeightConstraint.priority = .required

        // A lower-priority constraint makes the scroll view shrink-wrap its content
        // so it doesn't scroll when all content fits on screen.
        scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalTo: stackView.heightAnchor)
        scrollViewHeightConstraint?.priority = .defaultHigh

        scrollViewTopAnchor = view.bottomAnchor.constraint(equalTo: scrollView.topAnchor)
        scrollViewBottomAnchor = view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            maxHeightConstraint,
            scrollViewHeightConstraint!,
            scrollViewTopAnchor!
        ])

        let dismissView = UIView()
        dismissView.backgroundColor = UIColor.clear
        dismissView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissView)

        dismissView.isAccessibilityElement = true
        dismissView.accessibilityLabel = L10n.accessibilityDismiss
        dismissView.accessibilityTraits = [.button]
        NSLayoutConstraint.activate([
            dismissView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dismissView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dismissView.topAnchor.constraint(equalTo: view.topAnchor),
            dismissView.bottomAnchor.constraint(equalTo: scrollView.topAnchor)
        ])

        let dismissGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        dismissGestureRecognizer.delegate = self
        dismissView.addGestureRecognizer(dismissGestureRecognizer)

        if let title = title {
            addTitle(title, titleColor: colors.title)
        }

        // make actions a bit smaller on tiny phones
        if view.bounds.height < 600 {
            actionHeight = 64
        }
    }

    func addAction(action: OptionAction) {
        if actionsAdded > 0 { addDivider() }

        let actionView = SimpleActionView(frame: .zero, action: action, delegate: self, themeOverride: themeOverride, iconTintStyle: iconTintStyle)
        NSLayoutConstraint.activate([
            actionView.heightAnchor.constraint(greaterThanOrEqualToConstant: actionHeight)
        ])
        stackView.addArrangedSubview(actionView)
        NSLayoutConstraint.activate([
            actionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        actionView.actionWasAdded()

        actionsAdded += 1
    }

    func addDescriptiveActions(title: String, message: String?, icon: String, actions: [OptionAction]) {
        let actionView = DescriptiveActionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: actionHeight), title: title, message: message, icon: icon, actions: actions, delegate: self, themeOverride: themeOverride, iconTintStyle: iconTintStyle)
        stackView.addArrangedSubview(actionView)
        NSLayoutConstraint.activate([
            actionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        actionView.actionWasAdded()

        actionsAdded += 1
    }

    func addAttributedDescriptiveActions(title: String, message: String, icon: String, actions: [OptionAction]) {
        let actionView = DescriptiveActionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: actionHeight), title: title, message: message, icon: icon, actions: actions, delegate: self, themeOverride: themeOverride, iconTintStyle: iconTintStyle) { [weak self] in
            self?.backgroundTapped()
        }
        stackView.addArrangedSubview(actionView)
        NSLayoutConstraint.activate([
            actionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        actionView.actionWasAdded()

        actionsAdded += 1
    }

    func addSegmentedAction(name: String, icon: String?, actions: [OptionAction]) {
        if actionsAdded > 0 { addDivider() }

        let actionView = MultipleActionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: actionHeight), name: name, icon: icon, actions: actions, themeOverride: themeOverride)
        NSLayoutConstraint.activate([
            actionView.heightAnchor.constraint(greaterThanOrEqualToConstant: actionHeight)
        ])
        stackView.addArrangedSubview(actionView)
        NSLayoutConstraint.activate([
            actionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        actionView.actionWasAdded()

        actionsAdded += 1
    }

    func aboutToPresentOptions(bottomPadding: CGFloat) {
        let bottomPaddingView = UIView()
        NSLayoutConstraint.activate([
            bottomPaddingView.heightAnchor.constraint(equalToConstant: bottomPadding),
            bottomPaddingView.widthAnchor.constraint(equalToConstant: 280)
        ])
        stackView.addArrangedSubview(bottomPaddingView)
    }

    // MARK: - Animate in/out

    func animateIn() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.bottomCardAnimationTime, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            self?.scrollViewTopAnchor?.isActive = false
            self?.scrollViewBottomAnchor?.isActive = true
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

            self?.view?.layoutIfNeeded()
        }, completion: nil)
    }

    func animateOut(optionChosen: Bool) {
        view?.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.bottomCardAnimationTime, animations: { [weak self] in
            self?.scrollViewBottomAnchor?.isActive = false
            self?.scrollViewTopAnchor?.isActive = true

            self?.view.backgroundColor = UIColor.clear

            self?.view?.layoutIfNeeded()
        }) { [weak self] _ in
            self?.delegate?.controllerDidAnimateOut(optionChosen: optionChosen)
        }
    }

    @objc private func backgroundTapped() {
        animateOut(optionChosen: false)
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view?.isDescendant(of: scrollView) == false
    }

    // MARK: - Drawing Helpers

    private func addTitle(_ title: String, titleColor: UIColor) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        stackView.addArrangedSubview(containerView)

        let label = UILabel()
        label.font = UIFont.font(ofSize: 13, weight: .bold, scalingWith: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.text = title
        label.textColor = titleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.trailingAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: layoutHorizontalMargin),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -layoutHorizontalMargin),
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    private func addDivider() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 1)
        ])
        stackView.addArrangedSubview(containerView)

        let dividerView = UIView()
        dividerView.backgroundColor = AppTheme.tableDividerColor(for: themeOverride)
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(dividerView)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: layoutHorizontalMargin),
            containerView.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: -layoutHorizontalMargin),
            dividerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dividerView.topAnchor.constraint(equalTo: containerView.topAnchor)
        ])
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        portraitOnly ? .portrait : .allButUpsideDown
    }
}
