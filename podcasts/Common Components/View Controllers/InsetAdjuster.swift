import Foundation
import UIKit

/// Class to adjust scroll insets and scroll indicator depending of mini-player visibility and multi-select being enabled
class InsetAdjuster {

    let ignoreMiniPlayer: Bool

    init(ignoreMiniPlayer: Bool = false) {
        self.ignoreMiniPlayer = ignoreMiniPlayer
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    var isMultiSelectEnabled: Bool = false {
        didSet {
            miniPlayerVisibilityDidChange()
        }
    }

    private weak var scrollViewAdjustableToMiniPlayer: UIScrollView?

    func setupInsetAdjustmentsForMiniPlayer(scrollView: UIScrollView) {
        guard scrollViewAdjustableToMiniPlayer == nil else {
            // This method should only be called once for each ViewController
            return
        }
        scrollViewAdjustableToMiniPlayer = scrollView

        NotificationCenter.default.addObserver(self, selector: #selector(miniPlayerVisibilityDidChange), name: Constants.Notifications.miniPlayerDidDisappear, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(miniPlayerVisibilityDidChange), name: Constants.Notifications.miniPlayerDidAppear, object: nil)

        miniPlayerVisibilityDidChange()
    }

    @objc func miniPlayerVisibilityDidChange() {
        guard let scrollView = scrollViewAdjustableToMiniPlayer else {
            return
        }
        scrollView.updateContentInset(multiSelectEnabled: self.isMultiSelectEnabled, ignoreMiniPlayer: ignoreMiniPlayer)
    }
}
