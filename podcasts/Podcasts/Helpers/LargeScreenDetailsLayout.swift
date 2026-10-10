import PocketCastsUtils
import UIKit

/// The large screen layout of the podcast and playlist pages (`FeatureFlag.largeScreenPodcastDetails`).
///
/// A `UIArrangementViewController` shows the page's header as its primary view and the episode
/// list as its secondary one. When the arrangement has room, the header sits in a column next to
/// the list. Otherwise it only shows the primary view, and the list covers it with the header as
/// its first row, like on iPhone.
///
/// The list stays in the page's own view, because its cells and section headers host view
/// controllers that are children of the page. It follows the list pane through `listGuide`.
@available(iOS 27.1, *)
final class LargeScreenDetailsLayout {
    let arrangementController = UIArrangementViewController()
    let headerPane = LargeScreenDetailsPaneViewController()
    let listPane = LargeScreenDetailsPaneViewController()

    /// The frame of the list: the list pane when it's next to the header, otherwise the whole page
    let listGuide = UILayoutGuide()

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
    private var horizontalSizeClass: UIUserInterfaceSizeClass?
    private var listLeftConstraint: NSLayoutConstraint?
    private var listRightConstraint: NSLayoutConstraint?

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

        view.addLayoutGuide(listGuide)
        let listLeftConstraint = listGuide.leftAnchor.constraint(equalTo: view.leftAnchor)
        let listRightConstraint = view.rightAnchor.constraint(equalTo: listGuide.rightAnchor)
        NSLayoutConstraint.activate([
            listGuide.topAnchor.constraint(equalTo: view.topAnchor),
            listGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            listLeftConstraint,
            listRightConstraint
        ])
        self.listLeftConstraint = listLeftConstraint
        self.listRightConstraint = listRightConstraint
    }

    /// Reads whether the arrangement shows the list next to the header and moves `listGuide` to
    /// the list pane. Returns `true` when the header moved between its column and the list.
    func update() -> Bool {
        guard let view = parent?.view, let windowScene = view.window?.windowScene, let listPaneView = listPane.view else { return false }

        // `MainTabBarController` forces a compact size class on iPad, which its tabs don't always
        // undo after launch, so pass the scene's own size class to the arrangement.
        let horizontalSizeClass = windowScene.traitCollection.horizontalSizeClass
        if self.horizontalSizeClass != horizontalSizeClass {
            self.horizontalSizeClass = horizontalSizeClass
            arrangementController.traitOverrides.horizontalSizeClass = horizontalSizeClass
        }

        arrangementController.view.layoutIfNeeded()
        let isSplit = arrangementController.state(for: .secondary)?.isHidden == false
            && listPaneView.window != nil
            && !listPaneView.bounds.isEmpty

        let listFrame = isSplit ? listPaneView.convert(listPaneView.bounds, to: view) : view.bounds
        if listLeftConstraint?.constant != listFrame.minX {
            listLeftConstraint?.constant = listFrame.minX
        }
        if listRightConstraint?.constant != view.bounds.maxX - listFrame.maxX {
            listRightConstraint?.constant = view.bounds.maxX - listFrame.maxX
        }

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
    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
    }
}
