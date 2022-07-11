import CoreSpotlight
import Intents
import MediaPlayer
import UIKit

class ChapterIntentHandler: NSObject, SJChapterIntentHandling {
    func handle(intent: SJChapterIntent, completion: @escaping (SJChapterIntentResponse) -> Void) {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")
        // TODO: we should really open the app to the episode screen
        // Donate as User Activity
        userActivity.isEligibleForSearch = true
        let direction = intent.skipForward
        userActivity.title = "Skipping to \(direction)"
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "\(direction) chapter"
        userActivity.becomeCurrent()
        let response = SJChapterIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }
}
