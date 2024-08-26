import Foundation
import Speech
import NaturalLanguage

class TranscriptSyncModel {
    static let shared = TranscriptSyncModel()

    var words: [(TimeInterval, TimeInterval, String)] = [] {
        didSet {
            timestamps = words.map { ($0.0, $0.1) }
        }
    }

    var reference: String = ""

    func update(_ reference: SFTranscription, offset: TimeInterval) {
        reference.segments.forEach {
            words.append((offset + $0.timestamp, $0.duration, $0.substring))
        }

        wordByWord()
    }

    func reset() {
        words = []
        reference = ""
        matchedWords = []
        timestamps = []
    }

    // MARK: - Alignment algorithm

    var matchedWords: [Word] = []

    var timestamps: [(TimeInterval, TimeInterval)] = []

    func wordByWord() {
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
            return word1 == word2 ? matchScore : mismatchScore
        }

        // Perform sequence alignment
        func alignSequences(subtitle: String, transcript: [String], transcriptTimestamps: [(timestamp: TimeInterval, duration: TimeInterval)]) -> ([NSRange?], [String], [(timestamp: TimeInterval, duration: TimeInterval)]) {
            guard !subtitle.isEmpty, !transcript.isEmpty else { return ([], [], []) }

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

        // We need to do A LOT of work in performance
        // For testing purposed I limit the transcript to just 500 words
        // otherwise the app crashes, becomes slow, etc etc
        let subtitle = String(reference)
        let transcript = words.map { $0.2 }

        let (alignedSubtitle, alignedTranscript, alignedTimestamps) = alignSequences(subtitle: subtitle, transcript: transcript, transcriptTimestamps: timestamps)

        matchedWords = alignedSubtitle.enumerated().compactMap { index, range in
            guard let range else { return nil }

            return Word(timestamp: alignedTimestamps[index].timestamp, duration: alignedTimestamps[index].duration, characterRange: range)
        }
    }

    var previousWord: Word?

    public func firstWord(containing secondsValue: TimeInterval) -> Word? {
        if let word = matchedWords
            .first(where: { $0.contains(timeInSeconds: secondsValue) }) {
                previousWord = word
                return word
            } else {

                // In this case here we don't have any match
                // We have a lot of things we can do:
                // Improve the detection algorithm
                // Or we can just optimistically highlight something in the hopes
                // that is the correct word

                // Check what is the next word we'll highlight
                if let nextOne = matchedWords.first(where: { $0.timestamp > secondsValue }) {

                    // Calculate the time difference between the next one and the current time
                    let difference = nextOne.timestamp - secondsValue

                    if let previousWord {
                        let location = previousWord.characterRange.location + previousWord.characterRange.length

                        let nextOneLocation = nextOne.characterRange.location

                        let range = NSRange(location: location, length: nextOneLocation - location)

                        let test = reference[range]

                        // Highlight whatever is in between
                        if test.count > 2 {
                            return Word(timestamp: 0, duration: 0, characterRange: range)
                        }

                    }
                }

                return nil
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

public extension String {
  subscript(value: Int) -> Character {
    self[index(at: value)]
  }
}

public extension String {
  subscript(value: NSRange) -> Substring {
    self[value.lowerBound..<value.upperBound]
  }
}

public extension String {
  subscript(value: CountableClosedRange<Int>) -> Substring {
    self[index(at: value.lowerBound)...index(at: value.upperBound)]
  }

  subscript(value: CountableRange<Int>) -> Substring {
    self[index(at: value.lowerBound)..<index(at: value.upperBound)]
  }

  subscript(value: PartialRangeUpTo<Int>) -> Substring {
    self[..<index(at: value.upperBound)]
  }

  subscript(value: PartialRangeThrough<Int>) -> Substring {
    self[...index(at: value.upperBound)]
  }

  subscript(value: PartialRangeFrom<Int>) -> Substring {
    self[index(at: value.lowerBound)...]
  }
}

private extension String {
  func index(at offset: Int) -> String.Index {
    index(startIndex, offsetBy: offset)
  }
}
