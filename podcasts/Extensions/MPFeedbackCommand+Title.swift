import MediaPlayer

public extension MPFeedbackCommand {
    func setTitle(title: String) {
        localizedTitle = title
        localizedShortTitle = title
    }
}
