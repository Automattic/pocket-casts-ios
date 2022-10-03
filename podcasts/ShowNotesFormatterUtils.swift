import Foundation

class ShowNotesFormatterUtils {
    private static let regexTimePattern = "(\\A|\\s|>|[^a-zsA-Z_0-9/])(\\d{0,2}:?\\d{1,2}:\\d{2})(<|[^a-zsA-Z_0-9\"]|\\s|\\z)"
    private static let playerTimePattern = "$1<a href=\"http://localhost/#playerJumpTo=$2\">$2</a>$3"
    private static let regexATagPattern = "(<a.*?>.*?<\\/\\w?a>)"

    class func convertToLinks(stringWithTimes: String) -> String {
        do {
            var outString = stringWithTimes

            let aTagRegex = try NSRegularExpression(pattern: ShowNotesFormatterUtils.regexATagPattern)
            var aTagPlaceholderMap = [String: String]()

            aTagRegex.enumerateMatches(in: outString, options: [], range: NSMakeRange(0, outString.count)) { match, _, _ in
                if let match = match, let rangeOfMatch = Range(match.range, in: outString) {
                    let link = String(outString[rangeOfMatch])
                    let placeholderCount = aTagPlaceholderMap.count
                    let linkPlaceholder = "!PC_A_TAG_PLACEHOLDER_\(placeholderCount)!"
                    aTagPlaceholderMap[linkPlaceholder] = link
                }
            }

            for (placeholder, link) in aTagPlaceholderMap {
                outString = outString.replacingOccurrences(of: link, with: placeholder)
            }

            let timestampRegex = try NSRegularExpression(pattern: ShowNotesFormatterUtils.regexTimePattern)
            outString = timestampRegex.stringByReplacingMatches(in: outString, options: [], range: NSMakeRange(0, outString.count), withTemplate: ShowNotesFormatterUtils.playerTimePattern)

            for (placeholder, link) in aTagPlaceholderMap {
                outString = outString.replacingOccurrences(of: placeholder, with: link)
            }

            return outString
        } catch {
            return stringWithTimes
        }
    }
}
