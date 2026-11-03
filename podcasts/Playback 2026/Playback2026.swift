import UIKit
import PocketCastsUtils

enum Playback2026 {
    /// The single check every entry point (Podcasts sheet, Profile banner) and the story flow use.
    static var isAvailable: Bool {
        FeatureFlag.playback2026.enabled
    }

    // MARK: - Entry points

    static func start(from viewController: UIViewController) {
        // TODO: Present the Playback 2026 story flow
    }

    // MARK: - Podcasts sheet

    private static let hasShownSheetKey = "playback2026SheetHasBeenShown"

    static var hasShownSheet: Bool {
        get { UserDefaults.standard.bool(forKey: hasShownSheetKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasShownSheetKey) }
    }

    static func shouldShowSheet(isAvailable: Bool = Playback2026.isAvailable, hasShownSheet: Bool = Playback2026.hasShownSheet) -> Bool {
        isAvailable && !hasShownSheet
    }

    static func showSheetIfNeeded(in viewController: UIViewController) {
        guard shouldShowSheet(), viewController.presentedViewController == nil else {
            return
        }

        let sheet = Playback2026Sheet { [weak viewController] in
            guard let viewController else { return }
            viewController.dismiss(animated: true) {
                start(from: viewController)
            }
        }
        BottomSheetSwiftUIWrapper.present(sheet, autoSize: true, in: viewController)
    }
}
