import Foundation

protocol Filter {
    func filter(_ input: String) -> String
}

struct ComposeFilter: Filter {
    let filters: [Filter]

    func filter(_ input: String) -> String {
        let filteredText: String = filters.reduce(input) { partialResult, filter in
            return filter.filter(partialResult)
        }
        return filteredText
    }

    static let transcriptFilter = ComposeFilter(filters: [RegexFilter.vttTagsFilter, RegexFilter.speakerFilter, RegexFilter.newLinesFilter, SuffixFilter.addSpaceWhenNotEndofLine])
}

struct RegexFilter: Filter {

    let pattern: String
    let replacement: String

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

    static let vttTagsFilter = RegexFilter(pattern: "<[^>]*>", replacement: "")
    static let speakerFilter = RegexFilter(pattern: "Speaker \\d?:", replacement: "")
    static let newLinesFilter = RegexFilter(pattern: "\\.\\z", replacement: ".\n")
    
}

struct SuffixFilter: Filter {
    let condition: String
    let replacement: String

    func filter(_ input: String) -> String {
        return input.hasSuffix(condition) ? input : input.appending(replacement)
    }
}

extension SuffixFilter {
    static let addSpaceWhenNotEndofLine = SuffixFilter(condition: ".\n", replacement: " ")
}
