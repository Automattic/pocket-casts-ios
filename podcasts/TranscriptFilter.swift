import Foundation

protocol TranscriptFilter {
    func filter(_ input: String) -> String
}

struct ComposeFilter: TranscriptFilter {
    private let filters: [TranscriptFilter]

    func filter(_ input: String) -> String {
        let filteredText: String = filters.reduce(input) { partialResult, filter in
            return filter.filter(partialResult)
        }
        return filteredText
    }

    static let transcriptFilter = ComposeFilter(filters: [
        RegexFilter.vttTagsFilter,
        RegexFilter.speakerFilter,
        RegexFilter.notfullStopNewLineFilter,
        RegexFilter.fullStopNewLineFilter,
    ])
}

struct RegexFilter: TranscriptFilter {

    private let pattern: String
    private let replacement: String

    func filter(_ input: String) -> String {
        return regexSearchReplace(input: input, pattern: pattern, replacement: replacement)
    }

    private func regexSearchReplace(input: String, pattern: String, replacement: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(input.startIndex..., in: input)
            let result = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: replacement)
            return result
        } catch {
            return input
        }
    }
}

extension RegexFilter {
    // Remove VTT tags, for example: <Speaker 1> to ""
    static let vttTagsFilter = RegexFilter(pattern: "<[^>]*>", replacement: "")
    // Remove SRT tags, for example: "Speaker 1: " to ""
    static let speakerFilter = RegexFilter(pattern: "Speaker \\d?: *", replacement: "")
    // Ensure that any full stop starts a new line
    static let fullStopNewLineFilter = RegexFilter(pattern: "[\\!\\?\\.][ \\t]*", replacement: ".\n")
    // Ensure that end of cues have a space when appended to the next cue
    static let notfullStopNewLineFilter = RegexFilter(pattern: "([^\\!\\?\\.])\\z", replacement: "$0 ")
}

struct SuffixFilter: TranscriptFilter {
    private let condition: String
    private let replacement: String

    func filter(_ input: String) -> String {
        return input.hasSuffix(condition) ? input : input.appending(replacement)
    }
}

extension SuffixFilter {
    static let addSpaceWhenNotEndofLine = SuffixFilter(condition: ".\n", replacement: " ")
}
