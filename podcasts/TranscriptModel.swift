import Foundation
import Speech
import SwiftSubtitles
import NaturalLanguage

enum TranscriptFormat: String {
    case srt = "application/srt"
    case vtt = "text/vtt"
    case textHTML = "text/html"

    var fileExtension: String {
        switch self {
        case .srt:
            return "srt"
        case .vtt:
            return "vtt"
        case .textHTML:
            return "html"
        }
    }

    // Transcript formats we support in order of priority of use
    static let supportedFormats: [TranscriptFormat] = [.srt, .vtt]
}

struct TranscriptCue: Sendable {
    let startTime: Double
    let endTime: Double
    let characterRange: NSRange

    @inlinable public func contains(timeInSeconds seconds: Double) -> Bool {
        seconds >= self.startTime && seconds <= self.endTime
    }
}

extension NSAttributedString: @unchecked Sendable {

}

class TranscriptModel: @unchecked Sendable {

    let attributedText: NSAttributedString
    let cues: [TranscriptCue]

    lazy var rawText: String = {
        attributedText.string
    }()

    init(attributedText: NSAttributedString, cues: [TranscriptCue]) {
        self.attributedText = attributedText
        self.cues = cues
    }

    static func makeModel(from transcriptText: String, format: TranscriptFormat) -> TranscriptModel? {
        if format == .textHTML {
            return TranscriptModel(attributedText: NSAttributedString(string: transcriptText), cues: [])
        }
        guard let subtitles = try? Subtitles(content: transcriptText, expectedExtension: format.fileExtension) else {
            return nil
        }

        let resultText = NSMutableAttributedString()
        var cues = [TranscriptCue]()
        for cue in subtitles.cues {
            let text = cue.text
            let attributedText = NSAttributedString(string: text + "\n")
            let startPosition = resultText.length
            let endPosition = attributedText.length
            let range = NSRange(location: startPosition, length: endPosition)
            resultText.append(attributedText)
            let entry = TranscriptCue(startTime: cue.startTimeInSeconds, endTime: cue.endTimeInSeconds, characterRange: range)
            cues.append(entry)
        }

        return TranscriptModel(attributedText: resultText, cues: cues)
    }

    @inlinable public func firstCue(containing secondsValue: Double) -> TranscriptCue? {
        self.cues.first { $0.contains(timeInSeconds: secondsValue) }
    }

    var allSpeechToText: [String] = [] {
        didSet {
            print("$$ \(allSpeechToText.joined(separator: " "))")
            print("$$")
        }
    }
    var timestamps: [(TimeInterval, TimeInterval)] = []

    var words: [Word] = []

    public func firstWord(containing secondsValue: TimeInterval) -> Word? {
        words
//            .filter { $0.timestamp != nil }
//            .sorted(by: { $0.timestamp!.seconds < $1.timestamp!.seconds })
            .first { $0.contains(timeInSeconds: secondsValue) }
    }

    func wordByWord(speechToText: SFTranscription) {
        // Calculate Levenshtein distance
        func levenshtein(aStr: String, bStr: String) -> Int {
            let a = Array(aStr)
            let b = Array(bStr)
            let m = a.count
            let n = b.count

            var dist = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

            for i in 0...m {
                dist[i][0] = i
            }
            for j in 0...n {
                dist[0][j] = j
            }

            for i in 1...m {
                for j in 1...n {
                    if a[i-1] == b[j-1] {
                        dist[i][j] = dist[i-1][j-1]
                    } else {
                        dist[i][j] = min(
                            dist[i-1][j] + 1,
                            dist[i][j-1] + 1,
                            dist[i-1][j-1] + 1
                        )
                    }
                }
            }

            return dist[m][n]
        }

        // Define constants
        let matchScore = 1
        let mismatchScore = -1
        let gapPenalty = -2

        struct TimedWord {
            let word: String
            let timestamp: TimeInterval
            let duration: TimeInterval
        }

        // Tokenize the text while preserving punctuation
        func tokenize(text: String) -> [String] {
            var words = [String]()
            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = text
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
                let word = String(text[tokenRange])
                words.append(word)
                return true
            }
            return words
        }

        func tokenizeWithRange(text: String) -> [(String, NSRange)] {
            var words = [(String, NSRange)]()
            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = text
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
                let word = String(text[tokenRange])
                words.append((word, NSRange(tokenRange, in: text)))
                return true
            }
            return words
        }

        // Preprocess subtitle words: return both original and normalized words
        func preprocessSubtitleWords(text: String) -> [(normalized: String, range: NSRange)] {
            let words = tokenizeWithRange(text: text)
            return words.map { ($0.lowercased(), $1) }
        }

        // Preprocess timed words: tokenize and normalize, preserving timestamps
        func preprocessTimedWords(text: [String], timestamps: [(timestamp: TimeInterval, duration: TimeInterval)]) -> [TimedWord] {
            var timedWords = [TimedWord]()
            for (index, word) in text.enumerated() {
                timedWords.append(TimedWord(word: word.lowercased(), timestamp: timestamps[index].timestamp, duration: timestamps[index].duration))
            }
            return timedWords
        }

        // Define the scoring function
        func score(word1: String, word2: String) -> Int {
            let distance = levenshtein(aStr: word1, bStr: word2)
            return distance == 0 ? 1 : -distance
        }

        // Perform sequence alignment
        func alignSequences(subtitle: String, transcript: [String], transcriptTimestamps: [(timestamp: TimeInterval, duration: TimeInterval)]) -> ([NSRange?], [String], [(timestamp: TimeInterval, duration: TimeInterval)]) {
            let subtitleWords = preprocessSubtitleWords(text: subtitle)
            let transcriptTimedWords = preprocessTimedWords(text: transcript, timestamps: transcriptTimestamps)

            let lenSub = subtitleWords.count
            let lenTrans = transcriptTimedWords.count

            // Initialize the scoring matrix
            var S = Array(repeating: Array(repeating: 0, count: lenTrans + 1), count: lenSub + 1)

            // Initialize first row and column with gap penalties
            for i in 1...lenSub {
                S[i][0] = S[i-1][0] + gapPenalty
            }
            for j in 1...lenTrans {
                S[0][j] = S[0][j-1] + gapPenalty
            }

            // Populate the scoring matrix
            for i in 1...lenSub {
                for j in 1...lenTrans {
                    let match = S[i-1][j-1] + score(word1: subtitleWords[i-1].normalized, word2: transcriptTimedWords[j-1].word)
                    let delete = S[i-1][j] + gapPenalty
                    let insert = S[i][j-1] + gapPenalty
                    S[i][j] = max(match, delete, insert)
                }
            }

            // Traceback to get the aligned sequences
            var alignedSubtitle = [NSRange?]()
            var alignedTranscript = [String]()
            var alignedTimestamps = [(timestamp: TimeInterval, duration: TimeInterval)]()
            var i = lenSub
            var j = lenTrans

            while i > 0 && j > 0 {
                if S[i][j] == S[i-1][j-1] + score(word1: subtitleWords[i-1].normalized, word2: transcriptTimedWords[j-1].word) {
                    alignedSubtitle.append(subtitleWords[i-1].range)
                    alignedTranscript.append(transcriptTimedWords[j-1].word)
                    alignedTimestamps.append((transcriptTimedWords[j-1].timestamp, transcriptTimedWords[j-1].duration))
                    i -= 1
                    j -= 1
                } else if S[i][j] == S[i-1][j] + gapPenalty {
                    alignedSubtitle.append(subtitleWords[i-1].range)
                    alignedTranscript.append("-")
                    alignedTimestamps.append((-1, -1))  // Indicate a gap with a negative timestamp
                    i -= 1
                } else {
                    alignedSubtitle.append(nil)
                    alignedTranscript.append(transcriptTimedWords[j-1].word)
                    alignedTimestamps.append((transcriptTimedWords[j-1].timestamp, transcriptTimedWords[j-1].duration))
                    j -= 1
                }
            }

            while i > 0 {
                alignedSubtitle.append(subtitleWords[i-1].range)
                alignedTranscript.append("-")
                alignedTimestamps.append((-1, -1))
                i -= 1
            }

            while j > 0 {
                alignedSubtitle.append(nil)
                alignedTranscript.append(transcriptTimedWords[j-1].word)
                alignedTimestamps.append((transcriptTimedWords[j-1].timestamp, transcriptTimedWords[j-1].duration))
                j -= 1
            }

            return (alignedSubtitle.reversed(), alignedTranscript.reversed(), alignedTimestamps.reversed())
        }

        allSpeechToText.append(contentsOf: speechToText.segments.map { $0.substring })

        // Example usage
        let subtitle = rawText
        let transcript = allSpeechToText
        timestamps.append(contentsOf: speechToText.segments.map { ($0.timestamp, $0.duration) })

        let (alignedSubtitle, alignedTranscript, alignedTimestamps) = alignSequences(subtitle: subtitle, transcript: transcript, transcriptTimestamps: timestamps)

        words = alignedSubtitle.enumerated().compactMap { index, range in
            guard let range else { return nil }

            return Word(timestamp: alignedTimestamps[index].timestamp, duration: alignedTimestamps[index].duration, characterRange: range)
        }
    }
}

class Word {
    var timestamp: TimeInterval
    var duration: TimeInterval
    var characterRange: NSRange

    init(timestamp: TimeInterval, duration: TimeInterval, characterRange: NSRange) {
        self.timestamp = timestamp
        self.duration = duration
        self.characterRange = characterRange
    }

    func contains(timeInSeconds seconds: TimeInterval) -> Bool {
        seconds >= timestamp && seconds <= (timestamp + duration)
    }
}

class WordToAnalyze {
    let text: String
    var timestamp: TimeInterval
    var duration: TimeInterval
    var matched: Bool = false

    init(text: String, timestamp: TimeInterval, duration: TimeInterval, matched: Bool) {
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
        self.matched = matched
    }
}

// Levenshtein distance algorithm
func levDis(_ w1: String, _ w2: String) -> Int {
    let empty = [Int](repeating:0, count: w2.count)
    var last = [Int](0...w2.count)

    for (i, char1) in w1.enumerated() {
        var cur = [i + 1] + empty
        for (j, char2) in w2.enumerated() {
            cur[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
        }
        last = cur
    }
    return last.last!
}

func levDisNormalized(_ w1: String, _ w2: String) -> Double {
    let levDis = levDis(w1, w2)
    return 1 - Double(levDis) / Double(max(w1.count, w2.count))
}
