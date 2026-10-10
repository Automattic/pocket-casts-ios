import PocketCastsUtils
import UIKit

/// The large screen layout of the podcast and playlist pages (`FeatureFlag.largeScreenPodcastDetails`).
///
/// A `UIArrangementViewController` shows the page's header as its primary view and the episode
/// list as its secondary one. When the arrangement has room, the header sits in a column next to
/// the list, which the page moves into the list pane. Otherwise it only shows the primary view,
/// and the page shows the list itself with the header as its first row, like on iPhone.
///
/// The list's cells and section headers host view controllers, such as search fields, which move
/// with it, because UIKit requires a child's view to be in its parent's view.
@available(iOS 27.1, *)
final class LargeScreenDetailsLayout {
    let arrangementController = UIArrangementViewController()
    let headerPane = LargeScreenDetailsPaneViewController()
    let listPane = LargeScreenDetailsPaneViewController()

    /// The page's blurred artwork, behind the top of the header column
    let background: UIView

    /// Whether the header is in a column next to the list rather than the list's first row
    private(set) var isSplit = false

    var hasHeaderController: Bool {
        headerController != nil
    }

    /// How far the header column is scrolled, which the background follows
    var headerScrollOffset: CGFloat = 0 {
        didSet {
            layoutBackground()
        }
    }

    private weak var parent: UIViewController?
    private let backgroundMask = CAGradientLayer()
    private var headerController: UIViewController?
    private var listConstraints: [NSLayoutConstraint] = []

    static var isEnabled: Bool {
        FeatureFlag.largeScreenPodcastDetails.enabled
    }

    init(background: UIView) {
        self.background = background

        var arrangement = UISplitArrangement().axes(.horizontal)
        var headerProperties = arrangement.defaultViewProperties
        headerProperties.width.minimum = .absolute(Self.minimumHeaderWidth)
        headerProperties.width.preferred = .fractional(0.4)
        headerProperties.width.maximum = .absolute(Self.maximumHeaderWidth)
        arrangement.setViewProperties(headerProperties, for: .primary)
        arrangementController.setViewController(headerPane, for: .primary)
        arrangementController.setViewController(listPane, for: .secondary)
        arrangementController.updateArrangement(arrangement)

        // The arrangement can lay out its panes without the page laying out, for example after
        // a trait change, so the page reads the arrangement again whenever a pane changes
        for pane in [headerPane, listPane] {
            pane.onLayoutChange = { [weak self] in
                self?.parent?.view.setNeedsLayout()
            }
        }
    }

    /// Adds the arrangement to the page right behind its list
    func install(in parent: UIViewController, below listView: UIView) {
        self.parent = parent
        let view: UIView = parent.view

        background.isUserInteractionEnabled = false
        background.isHidden = true
        background.layer.mask = backgroundMask
        view.insertSubview(background, belowSubview: listView)

        parent.addChild(arrangementController)
        arrangementController.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(arrangementController.view, belowSubview: listView)
        arrangementController.view.anchorToAllSidesOf(view: view)
        arrangementController.didMove(toParent: parent)
    }

    /// The view controller that shows the list: the list pane next to the header column,
    /// otherwise the page
    var listHost: UIViewController? {
        isSplit ? listPane : parent
    }

    /// Moves the list into `listHost`, along with the view controllers the list hosts.
    ///
    /// - parameter views: The list, then the views above it, such as its footer.
    /// - parameter makeConstraints: The constraints of the views in the host's view.
    func moveList(_ views: [UIView], children: [UIViewController], makeConstraints: (_ hostView: UIView) -> [NSLayoutConstraint]) {
        guard let parent, let host = listHost, let hostView = host.view else { return }

        NSLayoutConstraint.deactivate(listConstraints)
        views.forEach { $0.removeFromSuperview() }
        let movedChildren = adopt(children, in: host)
        if host === parent {
            // The list covers the header pane, right above the arrangement
            var viewBelow: UIView = arrangementController.view
            for view in views {
                hostView.insertSubview(view, aboveSubview: viewBelow)
                viewBelow = view
            }
        } else {
            views.forEach { hostView.addSubview($0) }
        }
        movedChildren.forEach { $0.didMove(toParent: host) }
        listConstraints = makeConstraints(hostView)
        NSLayoutConstraint.activate(listConstraints)
    }

    /// Moves view controllers the list hosts to `listHost`, such as one created after the list moved
    func adoptListChildren(_ children: [UIViewController]) {
        guard let host = listHost else { return }

        adopt(children, in: host).forEach { $0.didMove(toParent: host) }
    }

    private func adopt(_ children: [UIViewController], in host: UIViewController) -> [UIViewController] {
        let movingChildren = children.filter { $0.parent !== host }
        for child in movingChildren {
            child.willMove(toParent: nil)
            child.removeFromParent()
            host.addChild(child)
        }
        return movingChildren
    }

    /// Reads whether the arrangement shows the list pane next to the header. Returns `true` when
    /// that changed, and the page then moves the list with `moveList`.
    func update() -> Bool {
        guard let parent, let windowScene = parent.view.window?.windowScene, let listPaneView = listPane.view else { return false }

        // `MainTabBarController` forces a compact size class on its tabs on iPad, which they don't
        // always undo after launch. Only then does the arrangement get the scene's size class;
        // otherwise it follows its own traits as the window resizes, such as when the Duo folds.
        let sceneSizeClass = windowScene.traitCollection.horizontalSizeClass
        let overrides = arrangementController.traitOverrides
        if parent.traitCollection.horizontalSizeClass == sceneSizeClass {
            if overrides.contains(UITraitHorizontalSizeClass.self) {
                arrangementController.traitOverrides.remove(UITraitHorizontalSizeClass.self)
            }
        } else if !overrides.contains(UITraitHorizontalSizeClass.self) || overrides.horizontalSizeClass != sceneSizeClass {
            arrangementController.traitOverrides.horizontalSizeClass = sceneSizeClass
        }

        // The arrangement decides on the current traits before the page reads its state
        arrangementController.updateTraitsIfNeeded()
        arrangementController.view.layoutIfNeeded()
        let isSplit = arrangementController.state(for: .secondary)?.isHidden == false
            && listPaneView.window != nil
            && !listPaneView.bounds.isEmpty

        let didChange = isSplit != self.isSplit
        if didChange {
            self.isSplit = isSplit
            background.isHidden = !isSplit
            if !isSplit {
                setHeaderController(nil)
            }
        }
        layoutBackground()
        return didChange
    }

    /// Shows `controller` in the header column. It's removed when the header becomes the list's
    /// first row again.
    func setHeaderController(_ controller: UIViewController?) {
        guard controller !== headerController else { return }

        if let headerController {
            headerController.willMove(toParent: nil)
            headerController.view.removeFromSuperview()
            headerController.removeFromParent()
        }
        headerController = controller
        headerScrollOffset = 0

        guard let controller, let paneView = headerPane.view else { return }

        headerPane.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        paneView.addSubview(controller.view)
        controller.view.anchorToAllSidesOf(view: paneView)
        controller.didMove(toParent: headerPane)
    }

    /// Centers the artwork glow on the header column, ending with the artwork at the top of it. It's
    /// wider than the column and continues behind the list, which is transparent, fading out over the
    /// start of the list so that the list's text stays legible over dark artwork.
    private func layoutBackground() {
        guard isSplit, let paneView = headerPane.view, let listPaneView = listPane.view, let superview = background.superview else { return }

        let headerFrame = paneView.convert(paneView.bounds, to: superview)
        let side = headerFrame.width * 1.6
        let bottom = headerFrame.minY + paneView.safeAreaInsets.top + Self.backgroundBottom - headerScrollOffset
        let frame = CGRect(x: headerFrame.midX - side / 2, y: bottom - side, width: side, height: side)
        background.frame = frame

        // The list is on the leading side in right-to-left layouts
        let isListOnRight = listPaneView.convert(listPaneView.bounds, to: superview).midX > headerFrame.midX
        let edge = isListOnRight ? headerFrame.maxX : headerFrame.minX
        var stops = Self.backgroundFade.map { (x: edge + (isListOnRight ? $0.distance : -$0.distance), opacity: $0.opacity) }
        if !isListOnRight {
            stops.reverse()
        }
        // The mask covers the blur, which spreads past the view's bounds
        let maskFrame = background.bounds.insetBy(dx: -Self.backgroundBlurSpread, dy: -Self.backgroundBlurSpread)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundMask.frame = maskFrame
        backgroundMask.startPoint = CGPoint(x: 0, y: 0.5)
        backgroundMask.endPoint = CGPoint(x: 1, y: 0.5)
        backgroundMask.colors = stops.map { UIColor(white: 0, alpha: $0.opacity).cgColor }
        backgroundMask.locations = stops.map { NSNumber(value: Double(($0.x - frame.minX - maskFrame.minX) / maskFrame.width)) }
        CATransaction.commit()
    }

    static let minimumHeaderWidth: CGFloat = 340
    static let maximumHeaderWidth: CGFloat = 420
    /// The bottom of the artwork, below the column's top safe area
    private static let backgroundBottom: CGFloat = 216
    /// How far the blur of `PodcastBlurHeaderView` and `PlaylistBlurHeaderView` spreads past their bounds
    private static let backgroundBlurSpread: CGFloat = 120
    /// The opacity of the background by distance into the list from the edge of the header column
    private static let backgroundFade: [(distance: CGFloat, opacity: CGFloat)] = [(-120, 1), (0, 0.55), (80, 0.2), (200, 0)]
}

extension UITableViewCell {
    /// Lets the table show through the cell's background, with no selection background, for a list
    /// next to the header column of `LargeScreenDetailsLayout`. Other cells set their selection
    /// style again when they're configured.
    func setRowBackgroundTransparent(_ isTransparent: Bool) {
        if let cell = self as? ThemeableCell {
            cell.isTransparent = isTransparent
        } else if let cell = self as? ThemeableSwipeCell {
            cell.isTransparent = isTransparent
        } else if isTransparent {
            selectionStyle = .none
        }
    }
}

/// A pane of `LargeScreenDetailsLayout`; the page lays out its content.
final class LargeScreenDetailsPaneViewController: UIViewController {
    /// Called when the arrangement moves, resizes or removes the pane
    var onLayoutChange: (() -> Void)?

    private var reportedFrame: CGRect?

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let frame = view.convert(view.bounds, to: nil)
        guard frame != reportedFrame else { return }
        reportedFrame = frame
        onLayoutChange?()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        reportedFrame = nil
        onLayoutChange?()
    }
}
