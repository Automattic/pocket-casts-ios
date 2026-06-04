import Foundation

struct TranscriptSelection: Equatable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let startCueIndex: Int
    let endCueIndex: Int
}

enum TranscriptSelectionLogic {
    static let defaultSelectionRadius = 3

    static func selectTranscript(
        around timestamp: TimeInterval,
        cues: [TranscriptCue],
        fullText: String,
        radius: Int = defaultSelectionRadius
    ) -> TranscriptSelection? {
        guard !cues.isEmpty else { return nil }

        let centerIndex = cueIndex(for: timestamp, in: cues) ?? nearestCueIndex(for: timestamp, in: cues)
        guard let centerIndex else { return nil }

        let startIndex = max(0, centerIndex - radius)
        let endIndex = min(cues.count - 1, centerIndex + radius)

        return selection(from: startIndex, to: endIndex, cues: cues, fullText: fullText)
    }

    static func adjustSelection(
        startCueIndex: Int,
        endCueIndex: Int,
        cues: [TranscriptCue],
        fullText: String
    ) -> TranscriptSelection? {
        guard !cues.isEmpty else { return nil }
        let clampedStart = max(0, min(startCueIndex, cues.count - 1))
        let clampedEnd = max(clampedStart, min(endCueIndex, cues.count - 1))

        return selection(from: clampedStart, to: clampedEnd, cues: cues, fullText: fullText)
    }

    // MARK: - Private

    private static func selection(
        from startIndex: Int,
        to endIndex: Int,
        cues: [TranscriptCue],
        fullText: String
    ) -> TranscriptSelection? {
        let nsString = fullText as NSString
        let firstCue = cues[startIndex]
        let lastCue = cues[endIndex]

        let rangeStart = firstCue.characterRange.location
        let rangeEnd = lastCue.characterRange.location + lastCue.characterRange.length
        let combinedRange = NSRange(location: rangeStart, length: rangeEnd - rangeStart)

        guard combinedRange.location + combinedRange.length <= nsString.length else { return nil }

        let text = nsString.substring(with: combinedRange).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        return TranscriptSelection(
            text: text,
            startTime: firstCue.startTime,
            endTime: lastCue.endTime,
            startCueIndex: startIndex,
            endCueIndex: endIndex
        )
    }

    static func bookmarkCueIndex(for timestamp: TimeInterval, in cues: [TranscriptCue]) -> Int? {
        cueIndex(for: timestamp, in: cues) ?? nearestCueIndex(for: timestamp, in: cues)
    }

    private static func cueIndex(for timestamp: TimeInterval, in cues: [TranscriptCue]) -> Int? {
        cues.firstIndex { $0.contains(timeInSeconds: timestamp) }
    }

    private static func nearestCueIndex(for timestamp: TimeInterval, in cues: [TranscriptCue]) -> Int? {
        guard !cues.isEmpty else { return nil }
        var bestIndex = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, cue) in cues.enumerated() {
            let midpoint = (cue.startTime + cue.endTime) / 2.0
            let distance = abs(midpoint - timestamp)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }
}
