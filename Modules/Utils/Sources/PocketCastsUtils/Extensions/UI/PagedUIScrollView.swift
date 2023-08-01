#if !os(watchOS)
import UIKit

/// A UIScrollView subclass that provides additional functionality for adding and manging horizontal pages.
public class PagedUIScrollView: UIScrollView {
    private var pageViews: [WeakRef<UIView>] = []

    private var lastPageTrailingConstraint: NSLayoutConstraint? = nil

    /// Returns the scroll view's width that is adjusted to be used in calculating the current page / x offset.
    private var pageWidth: Double {
        Double(bounds.width)
    }

    /// Calculates the current visible page based on the content offset
    public var currentPage: Int {
        let offset = round(contentOffset.x / pageWidth)

        guard isPagingEnabled, offset.isNumeric else { return 0 }

        return Int(offset)
    }

    public var totalPages: Int {
        let pages = Double(contentSize.width / pageWidth)

        guard isPagingEnabled, pages.isNumeric else { return 0 }

        return Int(pages)
    }

    /// Scrolls the given page into view
    public func scrollToPage(_ page: Int, animated: Bool = true) {
        guard isPagingEnabled else { return }

        var offset = contentOffset
        offset.x = pageWidth * Double(page)

        setContentOffset(offset, animated: animated)
    }

    /// Adds the view as a new page aligned after previous last page
    public func addPage(_ view: UIView, padding: UIEdgeInsets = .zero) {
        if view.superview != self {
            view.removeFromSuperview()
            addSubview(view)
        }

        let lastView = pageViews.last?.object
        pageViews.append(.init(view))

        let constraints = lastView.map { pageConstraints(view, after: $0, padding: padding) } ?? firstPageConstraints(view, padding: padding)

        // Deactivate the previous views trailing constraint
        lastPageTrailingConstraint?.isActive = false
        NSLayoutConstraint.activate(constraints)

        // Store the new last trailing constraint
        lastPageTrailingConstraint = constraints.first(where: { $0.firstAttribute == .trailing && $0.secondAttribute == .trailing })
    }

    // MARK: - Constraint Helpers

    private func firstPageConstraints(_ view: UIView, padding: UIEdgeInsets) -> [NSLayoutConstraint] {
        [
            view.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: padding.left),
            view.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: padding.top),
            view.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: padding.bottom),
            view.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: padding.right),
            view.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            view.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
        ]
    }

    private func pageConstraints(_ view: UIView, after: UIView, padding: UIEdgeInsets) -> [NSLayoutConstraint] {
        [
            view.leadingAnchor.constraint(equalTo: after.trailingAnchor, constant: padding.left),
            view.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: padding.right),
            view.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: padding.top),
            view.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: padding.bottom),
            view.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
        ]
    }
}
#endif
