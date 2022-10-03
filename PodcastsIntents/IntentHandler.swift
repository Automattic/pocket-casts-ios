import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        if intent is INPlayMediaIntent {
            return PlayMediaIntentHandler()
        } else if intent is SJChapterIntent {
            return ChapterIntentHandler()
        } else if intent is SJSleepTimerIntent {
            return SleepTimerIntentHandler()
        } else if intent is SJExtendSleepTimerIntent {
            return ExtendSleepTimerIntentHandler()
        } else if intent is SJOpenFilterIntent {
            return OpenFilterIntentHandler()
        }

        return self
    }
}
