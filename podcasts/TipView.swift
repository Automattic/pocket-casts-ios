import Foundation
import SwiftUI
import UIKit

struct TipView: View {
    let title: String
    let message: String?
    let sizeChanged: (CGSize)->()
    let onTap: (()->())?

    @EnvironmentObject var theme: Theme

    var body: some View {
        ContentSizeGeometryReader { _ in
            TipViewStatic(title: title, message: message, onTap: onTap)
        } contentSizeUpdated: { size in
            sizeChanged(size)
        }
    }
}

struct TipViewStatic: View {
    let title: String
    let message: String?
    let showClose: Bool
    let onTap: (()->())?

    init(title: String, message: String?, showClose: Bool = false, onTap: (() -> Void)?) {
        self.title = title
        self.message = message
        self.showClose = showClose
        self.onTap = onTap
    }

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(size: 15, style: .body, weight: .bold)
                        .foregroundColor(theme.primaryText01)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let message {
                        Text(message)
                            .font(size: 14, style: .body, weight: .regular)
                            .foregroundColor(theme.primaryText02)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
            .padding(16)
            .frame(maxHeight: .infinity)
            .onTapGesture {
                onTap?()
            }
        }.overlay(alignment: .topTrailing) {
            if showClose {
                Button() {
                    onTap?()
                } label: {
                    Image("close")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryText01)
                        .padding(8)
                }
            }
        }
    }
}

// MARK: - Popover presentation

/// Where a tip popover points.
enum TipAnchor {
    /// A source item (a `UIView` or `UIBarButtonItem`); the popover points at it. Preferred.
    case item(UIPopoverPresentationControllerSourceItem)
    /// A source view with an explicit rect within it, for cases that need to anchor to a sub-rect.
    case view(UIView, rect: CGRect = .null)
}

extension UIViewController {
    /// Presents a `TipViewStatic` as a themed, non-adaptive popover anchored to `anchor`, installing its own retained delegate so callers don't conform to `UIPopoverPresentationControllerDelegate`.
    @discardableResult
    func presentTip(
        title: String,
        message: String?,
        anchor: TipAnchor,
        arrow: UIPopoverArrowDirection = .up,
        idealSize: CGSize = CGSize(width: 300, height: 120),
        showClose: Bool = false,
        passthroughViews: [UIView]? = nil,
        onTap: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onShow: (() -> Void)? = nil
    ) -> UIViewController? {
        let tipView = TipViewStatic(title: title, message: message, showClose: showClose, onTap: onTap)
            .frame(maxWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        let hostingController = UIHostingController(rootView: tipView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.clipsToBounds = false
        hostingController.modalPresentationStyle = .popover
        hostingController.sizingOptions = [.preferredContentSize]

        guard let popover = hostingController.popoverPresentationController else { return nil }

        // The popover holds its delegate weakly, so tie its lifetime to the hosting controller, otherwise it deallocates immediately and the popover becomes a sheet on compact widths.
        let delegate = TipPopoverDelegate(onDismiss: onDismiss)
        objc_setAssociatedObject(hostingController, &tipPopoverDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        popover.delegate = delegate
        popover.permittedArrowDirections = arrow
        popover.backgroundColor = ThemeColor.primaryUi01()
        if let passthroughViews {
            popover.passthroughViews = passthroughViews
        }
        switch anchor {
        case .item(let item):
            popover.sourceItem = item
        case .view(let sourceView, let rect):
            popover.sourceView = sourceView
            popover.sourceRect = rect
        }

        present(hostingController, animated: true, completion: onShow)
        return hostingController
    }
}

private var tipPopoverDelegateKey: UInt8 = 0

/// Keeps a tip popover non-adaptive and forwards outside-tap dismissals. Retained via an associated object on the hosting controller (see `presentTip`).
private final class TipPopoverDelegate: NSObject, UIPopoverPresentationControllerDelegate {
    private let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)?) {
        self.onDismiss = onDismiss
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Keep the default popover behaviour instead of adapting to a sheet on compact widths.
        .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        onDismiss?()
    }
}

// MARK: - Previews
struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            TipView(title: L10n.referralsTipTitle(3), message: L10n.referralsTipMessage("2 Months"), sizeChanged: { _ in }, onTap: nil).setupDefaultEnvironment()
            Spacer()
        }
    }
}
