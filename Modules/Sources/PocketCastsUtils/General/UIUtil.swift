#if !os(watchOS) && !os(tvOS)
    import UIKit

    public enum UIUtil {
        public static func statusBarHeight(in window: UIWindow) -> CGFloat {
            window.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        }
    }
#endif
