import Foundation
import PocketCastsUtils

// Placeholder so that ExtendSleepTimerLiveActivityIntent can compile in widget extension, but never actually executes
// because it is a LiveActivityIntent which only runs in the app.
extension ExtendSleepTimerLiveActivityIntent {
    func extendSleepTimer(by duration: TimeInterval) {
        FileLog.shared.addMessage("ExtendSleepTimerLiveActivityIntent error: In Widget intent extension")
    }
}
