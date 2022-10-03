import AVKit
import UIKit

class PCRoutePickerView: AVRoutePickerView {
    func setupColors() {
        tintColor = ThemeColor.playerContrast02()
        activeTintColor = PlayerColorHelper.playerHighlightColor01(for: .dark)
    }

    // MARK: - Accessibility

    // we override these, because just setting them on an AVRoutePickerView doesn't do anything and by default the button is un-labelled
    override var isAccessibilityElement: Bool {
        get {
            true
        }
        set {}
    }

    override var accessibilityLabel: String? {
        get {
            L10n.playerRouteSelection
        }
        set {}
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            [.button]
        }
        set {}
    }
}
