import Speech

class TranscriptSyncChanges {

    init() {

    }

    var transcript: TranscriptModel?
    var transcriptView: UITextView = UITextView()
    var playbackManager: PlaybackManager = PlaybackManager.shared

    private func styleText(transcript: TranscriptModel, position: Double = 0) -> NSAttributedString {
        if let range = transcript.firstWord(containing: position)?.characterRange {
        }
        return NSAttributedString()
    }

    private func addObservers() {
        //addCustomObserver(Constants.Notifications.speechToTextAvailable, selector: #selector(receivedSpeechToTextContent))
    }

    var offset: TimeInterval = 0

    @objc private func receivedSpeechToTextContent(notification: NSNotification) {
        guard let text = notification.userInfo?["text"] as? SFTranscription,
              let offset = notification.userInfo?["offset"] as? TimeInterval else { return }

        self.offset = offset

        DispatchQueue.global().async {
            self.transcript?.wordByWord(speechToText: text)
        }
    }

    @objc private func updateTranscriptPosition() {
        let position = playbackManager.currentTime() - offset
        guard let transcript else {
            return
        }

        if let word = transcript.firstWord(containing: position) {
//            print(transcript.rawText[word.characterRange.lowerBound..<word.characterRange.upperBound])
            transcriptView.attributedText = styleText(transcript: transcript, position: position)
            // adjusting the scroll to range so it shows more text
            let scrollRange = NSRange(location: word.characterRange.location, length: word.characterRange.length)
            transcriptView.scrollRangeToVisible(scrollRange)
        }
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension Array {
    subscript(safe bounds: CountableClosedRange<Int>) -> ArraySlice<Element> {
        indices.contains(bounds.upperBound) && indices.contains(bounds.lowerBound) ? self[bounds] : []
    }
}
