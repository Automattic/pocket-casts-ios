import UIKit

class OptionsPickerRootController: UIViewController, UIGestureRecognizerDelegate, UISheetPresentationControllerDelegate {

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
    private var titleLabel: UILabel?
    private var dividerViews: [UIView] = []

    private var themeOverride: Theme.ThemeType?
    private var iconTintStyle: ThemeStyle = .primaryIcon01
    // this is not a weak var on purpose, nothing retains an OptionsPicker so we will until it dismisses
    var delegate: OptionsPicker?

    var portraitOnly = true

    private var scrollViewBottomAnchor: NSLayoutConstraint?
    private var scrollViewTopAnchor: NSLayoutConstraint?
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    private var scrollViewMaxHeightConstraint: NSLayoutConstraint?

    private weak var dismissView: UIView?
    private(set) var isPresentedAsSheet = false

    private let sheetTopPadding: CGFloat = LiquidGlass.isEnabled ? 20 : 12

    override var preferredStatusBarStyle: UIStatusBarStyle {
        overrideStatusBarStyle
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        scrollView.backgroundColor = colors.background

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)

        // Stack view fills the scroll view's content area at full width
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // The scroll view height matches its content height when possible,
        // but is capped at the available vertical space so it never overflows.
        let maxHeightConstraint = scrollView.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, constant: -75)
        maxHeightConstraint.priority = .required
        scrollViewMaxHeightConstraint = maxHeightConstraint

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
        self.dismissView = dismissView

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

        if let title {
            addTitle(title, titleColor: colors.title)
        }

        // make actions a bit smaller on tiny phones
        if view.bounds.height < 600 {
            actionHeight = 64
        }

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
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
        actionView.actionWasAdded(vc: self)

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
        actionView.actionWasAdded(vc: self)

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
        bottomPaddingView.backgroundColor = .clear
        NSLayoutConstraint.activate([
            bottomPaddingView.heightAnchor.constraint(equalToConstant: bottomPadding),
        ])
        stackView.addArrangedSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            bottomPaddingView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }

    // MARK: - Native Sheet Presentation

    /// Reconfigures the layout so the content fills a natively-presented sheet
    /// instead of animating in as a bottom card over a dimmed window.
    func configureForSheetPresentation() {
        isPresentedAsSheet = true

        if LiquidGlass.isEnabled {
            view.backgroundColor = scrollView.backgroundColor?.withAlphaComponent(0.85)
            scrollView.backgroundColor = .clear
        } else {
            view.backgroundColor = scrollView.backgroundColor
        }
        view.layer.cornerRadius = 0
        dismissView?.isHidden = true

        scrollViewTopAnchor?.isActive = false
        scrollViewMaxHeightConstraint?.isActive = false
        scrollViewHeightConstraint?.isActive = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: sheetTopPadding),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// The height needed to show every option without scrolling, capped at `maxHeight`.
    func preferredSheetHeight(limitedTo maxHeight: CGFloat, traitCollection: UITraitCollection) -> CGFloat {
        let contentHeight = stackView.systemLayoutSizeFitting(
            CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return min(contentHeight + sheetTopPadding, maxHeight)
    }

    // MARK: - UISheetPresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.controllerDidAnimateOut(optionChosen: false)
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
        if isPresentedAsSheet {
            // Collect this picker and any parent pickers it was stacked on
            // (e.g. the root menu under a submenu). Dismissing the bottom-most
            // one collapses the whole stack in a single animation, so choosing
            // a submenu option closes both sheets.
            var pickers = [self]
            var presenter = presentingViewController
            while let parentPicker = presenter as? OptionsPickerRootController {
                pickers.append(parentPicker)
                presenter = parentPicker.presentingViewController
            }
            presenter?.dismiss(animated: true) {
                for picker in pickers {
                    picker.delegate?.controllerDidAnimateOut(optionChosen: optionChosen)
                }
            }
            return
        }

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
        label.numberOfLines = 0
        label.text = title
        label.textColor = titleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        self.titleLabel = label
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.trailingAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: layoutHorizontalMargin),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -layoutHorizontalMargin),
            label.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
        ])
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
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
        dividerViews.append(dividerView)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: layoutHorizontalMargin),
            containerView.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: -layoutHorizontalMargin),
            dividerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dividerView.topAnchor.constraint(equalTo: containerView.topAnchor)
        ])
    }

    @objc private func themeDidChange() {
        let colors = Colors(theme: themeOverride ?? Theme.sharedTheme.activeTheme)

        if isPresentedAsSheet {
            if LiquidGlass.isEnabled {
                view.backgroundColor = colors.background.withAlphaComponent(0.85)
            } else {
                view.backgroundColor = colors.background
                scrollView.backgroundColor = colors.background
            }
        } else {
            scrollView.backgroundColor = colors.background
        }

        titleLabel?.textColor = colors.title

        for divider in dividerViews {
            divider.backgroundColor = AppTheme.tableDividerColor(for: themeOverride)
        }
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        portraitOnly ? .portrait : .allButUpsideDown
    }
}
