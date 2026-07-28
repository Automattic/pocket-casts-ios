import UIKit
import PocketCastsUtils

protocol PCSearchBarDelegate: AnyObject {
    func searchDidBegin()
    func searchDidEnd()
    func searchWasCleared()
    func searchTermChanged(_ searchTerm: String)
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void))
}

class PCSearchBarController: UIViewController {
    @IBOutlet var roundedBackgroundView: UIView!
    @IBOutlet var searchTextField: UITextField! {
        didSet {
            searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
    }

    @IBOutlet var searchIcon: UIImageView!
    @IBOutlet var cancelButton: UIButton! {
        didSet {
            cancelButton.setTitle(L10n.cancel, for: .normal)
            cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet var loadingSpinner: ThemeLoadingIndicator!

    @IBOutlet var roundedBgTrailingSpaceParent: NSLayoutConstraint!
    @IBOutlet var roundedBgTrailingSpaceToCancel: NSLayoutConstraint! {
        didSet {
            roundedBgTrailingSpaceToCancel.isActive = false // the cancel button is hidden by default
        }
    }

    @IBOutlet var clearSearchBtn: UIButton!

    private static let pillHeight: CGFloat = 32
    private static let pillBottomInset: CGFloat = 16

    static var defaultHeight: CGFloat {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let base = pillHeight + pillBottomInset
        return max(base, metric.scaledValue(for: base))
    }

    static let peekAmountBeforeAutoOpen: CGFloat = 20

    var shouldShowCancelButton = true
    var cancelButtonShowing = false

    /// Driven by the scrolling extension between `0` and `defaultHeight` to collapse/expand the
    /// bar in place — the bar's top stays anchored to the safe area, and the pill, icons and
    /// placeholder fade and shrink together. Set by `install(in:)`.
    private(set) var heightConstraint: NSLayoutConstraint?

    /// When `true`, the scrolling extension keeps the parent scroll view's `contentInset.top`
    /// matched to the bar's current height. Use this with plain-style `UITableView`s whose
    /// section headers pin to `adjustedContentInset.top` — otherwise headers stay pinned where
    /// the (now-collapsed) bar used to be, leaving a gap under the nav bar. Callers must also
    /// forward `scrollViewDidEndDecelerating` and `scrollViewDidEndScrollingAnimation`.
    var tracksContentInsetToBarHeight = false

    var searchDebounce = 1.seconds
    var searchTimer: Timer?

    var placeholderText = L10n.searchLabel {
        didSet {
            if isViewLoaded {
                updatePlaceholderColor()
            }
        }
    }

    var backgroundColorOverride: UIColor?

    var startWithToolbarHidden = true

    weak var searchDelegate: PCSearchBarDelegate?

    private var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        updateColors()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: PCSearchBarController, _) in
            controller.updateSize()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(searchRequest), name: Constants.Notifications.podcastSearchRequest, object: nil)
        updateSize()
        updateCollapseAppearance()
    }

    /// Installs the bar as a child of `parent`, pinned to the top safe area with leading and
    /// trailing anchored to `parent.view`. When `collapses` is `true`, creates the height
    /// constraint the scrolling extension drives between `0` and `defaultHeight`; when `false`,
    /// the bar stays pinned at `defaultHeight` and is not driven by scroll forwards. If
    /// `scrollView` is provided, also applies the initial top contentInset/offset so the bar
    /// starts visible.
    func install(in parent: UIViewController, attachedTo scrollView: UIScrollView? = nil, collapses: Bool = true) {
        view.translatesAutoresizingMaskIntoConstraints = false
        parent.addChild(self)
        parent.view.addSubview(view)
        didMove(toParent: parent)

        let heightConstraint = view.heightAnchor.constraint(equalToConstant: collapses ? 0 : Self.defaultHeight)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.topAnchor),
            heightConstraint
        ])
        if collapses {
            self.heightConstraint = heightConstraint
        }

        if let scrollView {
            scrollView.contentInset.top = Self.defaultHeight
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -Self.defaultHeight), animated: false)
        }
    }

    func updateCollapseAppearance() {
        let height = heightConstraint?.constant ?? Self.defaultHeight
        let progress = min(1, max(0, height / Self.defaultHeight))
        // Pill itself shrinks in place; contents fade on a steeper curve so the text/icons are
        // gone well before the pill finishes collapsing — closer to the native bar.
        let contentAlpha = max(0, progress * 1.66 - 1)
        searchIcon.alpha = contentAlpha
        searchTextField.alpha = contentAlpha
        clearSearchBtn.alpha = contentAlpha
        loadingSpinner.alpha = contentAlpha
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }

    @objc private func themeDidChange() {
        updateColors()
    }

    @objc private func searchRequest(notification: Notification) {
        if isVisible, let searchTerm = notification.object as? String {
            searchTextField.text = searchTerm
            clearSearchBtn.isHidden = false
            view.endEditing(true)
        }
    }

    private func updateColors() {
        if LiquidGlass.isEnabled {
            configureAppearance()
        } else {
            configureLegacyAppearnace()
        }
    }

    private func configureAppearance() {
        view.backgroundColor = .clear
        searchTextField.backgroundColor = .clear
        searchTextField.keyboardAppearance = AppTheme.keyboardAppearance()
        roundedBackgroundView.backgroundColor = ThemeColor.primaryField01()

        let textColor = ThemeColor.primaryText01()
        searchTextField.textColor = textColor
        cancelButton.setTitleColor(textColor, for: .normal)

        updatePlaceholderColor()

        let iconColor = ThemeColor.primaryIcon02()
        searchIcon.tintColor = iconColor
        clearSearchBtn.tintColor = iconColor
    }

    private func configureLegacyAppearnace() {
        view.backgroundColor = backgroundColorOverride ?? ThemeColor.secondaryUi01()
        searchTextField.backgroundColor = UIColor.clear
        searchTextField.keyboardAppearance = AppTheme.keyboardAppearance()
        roundedBackgroundView.backgroundColor = backgroundColorOverride == nil ? ThemeColor.secondaryField01() : ThemeColor.primaryField01()

        let textColor = backgroundColorOverride == nil ? ThemeColor.secondaryText01() : ThemeColor.primaryText01()
        searchTextField.textColor = textColor
        cancelButton.setTitleColor(textColor, for: .normal)

        updatePlaceholderColor()

        let iconColor = backgroundColorOverride == nil ? ThemeColor.secondaryIcon02() : ThemeColor.primaryIcon02()
        searchIcon.tintColor = iconColor
        clearSearchBtn.tintColor = iconColor
    }

    private func updatePlaceholderColor() {
        var placeholderColor = backgroundColorOverride == nil ? ThemeColor.secondaryText02() : ThemeColor.primaryText02()
        if LiquidGlass.isEnabled {
            placeholderColor = ThemeColor.primaryText02()
        }
        searchTextField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
    }

    @IBAction func cancelTapped(_ sender: Any) {
        clearSearchBtn.isHidden = true
        searchTextField.text = nil
        searchTextField.resignFirstResponder()
        hideCancelButton()

        searchDelegate?.searchDidEnd()
    }

    @IBAction func clearSearchTapped(_ sender: Any) {
        searchTextField.text = ""
        clearSearchBtn.isHidden = true

        searchDelegate?.searchWasCleared()
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)
        let imageSize = max(16, metric.scaledValue(for: 16))
        searchIcon.updateSizeConstraints(to: imageSize)

        let clearSearchSize = max(22, metric.scaledValue(for: 22))
        clearSearchBtn.updateSizeConstraints(to: clearSearchSize)

        view.updateSizeConstraints(to: Self.defaultHeight)
    }
}
