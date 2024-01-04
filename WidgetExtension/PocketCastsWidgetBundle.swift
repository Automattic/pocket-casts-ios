import SwiftUI
import WidgetKit

@main
struct PocketCastsWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        UpNextWidget()
        UpNextWidgetBold()
        NowPlayingLockScreenWidget()
        AppIconWidget()
        UpNextLockScreenWidget()
    }
}
