import SwiftUI
import WidgetKit

@main
struct PocketCastsWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        UpNextWidgetBold()
        UpNextWidget()
        NowPlayingLockScreenWidget()
        AppIconWidget()
        UpNextLockScreenWidget()
    }
}
