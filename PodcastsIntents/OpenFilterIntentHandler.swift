import CoreSpotlight
import Intents
import MediaPlayer
import UIKit

class OpenFilterIntentHandler: NSObject, SJOpenFilterIntentHandling {
    func handle(intent: SJOpenFilterIntent, completion: @escaping (SJOpenFilterIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        if let filterName = intent.filterName {
            userActivity.title = "Open \(filterName)"
            userActivity.suggestedInvocationPhrase = "Open \(filterName)"
        } else {
            userActivity.title = "Open Filter"
            userActivity.suggestedInvocationPhrase = "Open Filter"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.becomeCurrent()

        let response = SJOpenFilterIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }
}
