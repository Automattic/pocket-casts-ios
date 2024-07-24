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
        RegexFilter.fullStopEndofCueFilter
    ])

    static let htmlFilter = ComposeFilter(filters: [
        RegexFilter.breakLineFilter,
        RegexFilter.nbspFilter,
        RegexFilter.vttTagsFilter,
        RegexFilter.soundDescriptorFilter,
        RegexFilter.htmlSpeakerFilter,
        RegexFilter.emptySpacesAtEndOfLinesFilter,
        RegexFilter.doubleOrMoreSpacesFilter
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
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
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
    static let fullStopNewLineFilter = RegexFilter(pattern: "([\\!\\?\\.])\\s+", replacement: "$1\n")
    // Full Stop at end of cue
    static let fullStopEndofCueFilter = RegexFilter(pattern: "([\\!\\?\\.])\\z", replacement: "$1\n")
    // Ensure that end of cues have a space when appended to the next cue
    static let notfullStopNewLineFilter = RegexFilter(pattern: "([^\\!\\?\\.])\\z", replacement: "$1 ")
    // &nbsp filter
    static let nbspFilter = RegexFilter(pattern: "&nbsp;", replacement: " ")
    // <br> filter
    static let breakLineFilter = RegexFilter(pattern: "<br>|<BR>|<br/>|<BR/>|<BR />|<br />", replacement: "\n")
    // Sound descriptor filter. Ex: [laughs]
    static let soundDescriptorFilter = RegexFilter(pattern: "\\[[^\\]]*\\]", replacement: "")
    // Speaker names at start
    static let htmlSpeakerFilter = RegexFilter(pattern: "^[ ]*\\w+:\\s*", replacement: "")
    // Empty spaces at the end of lines
    static let emptySpacesAtEndOfLinesFilter = RegexFilter(pattern: "[ ]*\\n", replacement: "\n")
    // Double or more spaces
    static let doubleOrMoreSpacesFilter = RegexFilter(pattern: "[ ]+", replacement: " ")
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
