import SwiftUI
import WidgetKit

@main
struct PocketCastsWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidgetBold()
        UpNextWidgetBold()
        NowPlayingWidget()
        UpNextWidget()
        NowPlayingLockScreenWidget()
        AppIconWidget()
        UpNextLockScreenWidget()
        if #available(iOSApplicationExtension 17.0, *) {
            SleepTimerLiveActivityWidget()
        }
    }
}
