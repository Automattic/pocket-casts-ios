import UIKit

class OptionsPickerRootController: UIViewController, UISheetPresentationControllerDelegate {

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

    private var scrollView: UIScrollView!
    private var stackView: UIStackView!

    private var actionHeight: CGFloat = 72
    private let layoutHorizontalMargin = CGFloat(20)
    private var actionsAdded = 0

    private var themeOverride: Theme.ThemeType?
    private var iconTintStyle: ThemeStyle = .primaryIcon01
    // this is not a weak var on purpose, nothing retains an OptionsPicker so we will until it dismisses
    var delegate: OptionsPicker?

    private var sheetTopPadding: CGFloat {
        stackView.arrangedSubviews.count > 1 ? 12 : 0
    }

    func setup(title: String?, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle, colors: Colors? = nil) {
        let colors = colors ?? Colors(theme: themeOverride ?? Theme.sharedTheme.activeTheme)

        view.clipsToBounds = true
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

        // The scroll view fills the sheet; its content scrolls when the options
        // are taller than the available space.
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let title {
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
        actionView.actionWasAdded(vc: self)

        actionsAdded += 1
    }

    func addAttributedDescriptiveActions(title: String, message: String, icon: String, actions: [OptionAction]) {
        let actionView = DescriptiveActionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: actionHeight), title: title, message: message, icon: icon, actions: actions, delegate: self, themeOverride: themeOverride, iconTintStyle: iconTintStyle) { [weak self] in
            self?.animateOut(optionChosen: false)
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

    // MARK: - Native Sheet Presentation

    /// Applies the styling and per-action layout needed before the options are
    /// shown in a natively-presented sheet.
    func configureForSheetPresentation() {
        if LiquidGlass.isEnabled {
            view.backgroundColor = scrollView.backgroundColor?.withAlphaComponent(0.85)
            scrollView.backgroundColor = .clear
        } else {
            view.backgroundColor = scrollView.backgroundColor
        }

        scrollView.contentInset = UIEdgeInsets(top: sheetTopPadding, left: 0, bottom: 0, right: 0)

        for arrangedSubview in stackView.arrangedSubviews {
            (arrangedSubview as? SimpleActionView)?.configureForSheetPresentation()
        }
    }

    /// The height needed to show every option without scrolling, capped at `maxHeight`.
    func preferredSheetHeight(limitedTo maxHeight: CGFloat, traitCollection: UITraitCollection) -> CGFloat {
        let width = view.bounds.width > 0 ? view.bounds.width : 320
        let contentHeight = stackView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return min(contentHeight + sheetTopPadding, maxHeight)
    }

    // MARK: - UISheetPresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.controllerDidAnimateOut(optionChosen: false)
    }

    // MARK: - Dismissal

    func animateOut(optionChosen: Bool) {
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
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: layoutHorizontalMargin),
            containerView.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: -layoutHorizontalMargin),
            dividerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dividerView.topAnchor.constraint(equalTo: containerView.topAnchor)
        ])
    }
}
