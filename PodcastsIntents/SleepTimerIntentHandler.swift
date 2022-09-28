import CoreSpotlight
import Intents
import MediaPlayer
import UIKit

class SleepTimerIntentHandler: NSObject, SJSleepTimerIntentHandling {
    func handle(intent: SJSleepTimerIntent, completion: @escaping (SJSleepTimerIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        let minutes = intent.minutes
        if let minutes = minutes {
            userActivity.title = "Setting sleep timer to \(minutes) minutes"
        } else {
            userActivity.title = "Setting sleep timer"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Set sleep timer"
        userActivity.becomeCurrent()

        let response = SJSleepTimerIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }
}
