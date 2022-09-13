import SwiftUI
import WidgetKit

@main
struct PocketCastsWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        UpNextWidget()
        NowPlayingLockScreenWidget()
        AppIconWidget()
        UpNextLockScreenWidget()
    }
}
