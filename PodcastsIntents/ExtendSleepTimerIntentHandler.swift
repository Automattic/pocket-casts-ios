import CoreSpotlight
import Intents
import MediaPlayer
import UIKit

class ExtendSleepTimerIntentHandler: NSObject, SJExtendSleepTimerIntentHandling {
    func handle(intent: SJExtendSleepTimerIntent, completion: @escaping (SJExtendSleepTimerIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        let minutes = intent.minutes
        if let minutes = minutes {
            userActivity.title = "Extending sleep timer by \(minutes) minutes"
        } else {
            userActivity.title = "Extend sleep timer"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Extend sleep timer"
        userActivity.becomeCurrent()

        let response = SJExtendSleepTimerIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }
}
