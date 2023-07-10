import UIKit
import PocketCastsDataModel

extension SharingHelper {
    func shareLinkTo(episode: Episode, fromController: UIViewController, fromTableView tableView: UITableView, at indexPath: IndexPath) {
        let source = tableView.swipeButton(forLabel: L10n.share, at: indexPath) ?? tableView
        shareLinkTo(episode: episode, shareTime: 0, fromController: fromController, sourceRect: source.bounds, sourceView: source)
    }
}

private extension UITableView {
    func swipeButton(forLabel label: String, at indexPath: IndexPath) -> UIView? {
        cellForRow(at: indexPath)?.findViews(subclassOf: UIButton.self).first(where: { $0.accessibilityLabel == label })
    }
}

private extension UIView {
    func findViews<T: UIView>(subclassOf: T.Type) -> [T] {
        return recursiveSubviews.compactMap { $0 as? T }
    }

    var recursiveSubviews: [UIView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}
