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

    private var stackView: UIStackView!
    private var stackBgView: UIView!

    private let buttonCornerRadius: CGFloat = 8
    private var actionHeight: CGFloat = 72

    private var actionsAdded = 0

    private var themeOverride: Theme.ThemeType?
    private var iconTintStyle: ThemeStyle = .primaryIcon01
    // this is not a weak var on purpose, nothing retains an OptionsPicker so we will until it dismisses
    var delegate: OptionsPicker?

    var portraitOnly = true

    private var stackViewBottomAnchor: NSLayoutConstraint?
    private var stackViewTopAnchor: NSLayoutConstraint?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        overrideStatusBarStyle
    }

    func setup(title: String?, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle, colors: Colors? = nil) {
        let colors = colors ?? Colors(theme: themeOverride ?? Theme.sharedTheme.activeTheme)

        view.clipsToBounds = true
        view.layer.cornerRadius = 6
        self.themeOverride = themeOverride
        self.iconTintStyle = iconTintStyle

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

        view.addSubview(stackView)

        stackBgView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        stackBgView.layer.shadowOffset = CGSize(width: 0, height: -1)
        stackBgView.layer.shadowOpacity = 0.2
        stackBgView.layer.shadowRadius = 10
        stackBgView.layer.cornerRadius = 6
        stackBgView.layer.shadowPath = UIBezierPath(rect: stackBgView.layer.bounds).cgPath

        stackViewTopAnchor = view.bottomAnchor.constraint(equalTo: stackView.topAnchor)
        stackViewBottomAnchor = view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stackViewTopAnchor!
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
            dismissView.bottomAnchor.constraint(equalTo: stackView.topAnchor)
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

        let actionView = SimpleActionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: actionHeight), action: action, delegate: self, themeOverride: themeOverride, iconTintStyle: iconTintStyle)
        NSLayoutConstraint.activate([
            actionView.heightAnchor.constraint(equalToConstant: actionHeight)
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

    func addSegmentedAction(name: String, icon: String?, actions: [OptionAction]) {
        if actionsAdded > 0 { addDivider() }

        let actionView = MultipleActionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: actionHeight), name: name, icon: icon, actions: actions, themeOverride: themeOverride)
        NSLayoutConstraint.activate([
            actionView.heightAnchor.constraint(equalToConstant: actionHeight)
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
            self?.stackViewTopAnchor?.isActive = false
            self?.stackViewBottomAnchor?.isActive = true
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

            self?.view?.layoutIfNeeded()
        }, completion: nil)
    }

    func animateOut(optionChosen: Bool) {
        view?.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.bottomCardAnimationTime, animations: { [weak self] in
            self?.stackViewBottomAnchor?.isActive = false
            self?.stackViewTopAnchor?.isActive = true

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
        touch.view?.isDescendant(of: stackView) == false
    }

    // MARK: - Drawing Helpers

    private func addTitle(_ title: String, titleColor: UIColor) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 40)
        ])
        stackView.addArrangedSubview(containerView)

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.text = title
        label.textColor = titleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20)
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
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: 20),
            dividerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dividerView.topAnchor.constraint(equalTo: containerView.topAnchor)
        ])
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        portraitOnly ? .portrait : .allButUpsideDown
    }
}
