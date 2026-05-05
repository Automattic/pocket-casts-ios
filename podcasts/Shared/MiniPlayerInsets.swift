import UIKit

enum MiniPlayerInsets {
    /// Returns the baseline padding above the bottom edge, adjusted for the mini player if visible.
    /// Default baseline is 16pt.
    static func baseline(padding: CGFloat = 8) -> CGFloat {
        Constants.effectiveMiniPlayerOffset + padding
    }
}
