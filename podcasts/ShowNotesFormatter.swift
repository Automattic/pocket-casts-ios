
import Foundation

class ShowNotesFormatter {
    class func format(showNotes: String, tintColor: UIColor, convertTimesToLinks: Bool, bgColor: UIColor?, textColor: UIColor) -> String {
        let cssBgColor = bgColor?.hexString() ?? "transparent"

        return format(showNotes: showNotes, tintColor: tintColor, textColor: textColor, cssBgColor: cssBgColor, convertTimesToLinks: convertTimesToLinks)
    }

    class func formatInEpisode(customTitle: String, showNotes: String, tintColor: UIColor, convertTimesToLinks: Bool, bgColor: UIColor?, textColor: UIColor) -> String {
        let cssBgColor = bgColor?.hexString() ?? "transparent"

        return format(customTitle: customTitle, showNotes: showNotes, tintColor: tintColor, textColor: textColor, cssBgColor: cssBgColor, convertTimesToLinks: convertTimesToLinks)
    }

    private class func format(customTitle: String? = nil, showNotes: String, tintColor: UIColor, textColor: UIColor, cssBgColor: String, convertTimesToLinks: Bool) -> String {
        var styledShowNotes = "<html><head>" +
            "<meta http-equiv='Content-Type' content='text/html; charset=utf-16le'>" +
            "<meta name='viewport' content='initial-scale=1.0' />" +
            "<style type='text/css'>" +
            "body { font-family: '-apple-system'; font-size: 16px; line-height: 22px; letter-spacing: -0.1px;" +
            "background-color: \(cssBgColor);" +
            "color: \(textColor.hexString());" +
            "margin: 8px 16px; word-wrap: break-word; } " +
            "pre { white-space: pre-wrap; } " +
            "a { color:\(tintColor.hexString()); font-family:'-apple-system'; text-decoration:underline; } " +
            "h1,h2,h3,h4,h5,h6 { font-family: '-apple-system'; font-weight: normal; font-size: 16px; padding: 0; } " +
            "customTitle { font-family: '-apple-system'; font-weight: 500; font-size: 20px; padding: 0; }" +
            imageTag() +
            "</style>"

        let cleanedShowNotes = removeHtml(string: showNotes)
        styledShowNotes = styledShowNotes + "</head><body>"

        if let customTitle {
            styledShowNotes = styledShowNotes + "<p><customTitle>\(customTitle)</customTitle></p>"
        }

        styledShowNotes = styledShowNotes + "\(cleanedShowNotes)</body></html>"

        if convertTimesToLinks {
            styledShowNotes = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: styledShowNotes)
        }

        return styledShowNotes
    }

    private class func removeHtml(string: String) -> String {
        let bodyStartRange = string.range(of: "<body>")
        let bodyEndRange = string.range(of: "</body>")

        if let startRange = bodyStartRange, let endRange = bodyEndRange {
            let rangeToKeep = Range(uncheckedBounds: (lower: startRange.upperBound, upper: endRange.lowerBound))
            return String(string[rangeToKeep])
        } else {
            return string.replacingOccurrences(of: "<body>", with: "").replacingOccurrences(of: "</body>", with: "").replacingOccurrences(of: "<html>", with: "").replacingOccurrences(of: "</html>", with: "")
        }
    }

    private class func imageTag() -> String {
        let hideImagesInShowNotes = UserDefaults.standard.bool(forKey: Constants.UserDefaults.hideImagesInShowNotes)
        if hideImagesInShowNotes {
            return "img { display: none; } html { -webkit-text-size-adjust: none; }"
        } else {
            return "img { width: auto !important; height: auto !important; max-width:100%; max-height: auto; padding-bottom: 10px; padding-top: 10px; display: block; } img[src*=\"coverart\" i] { display: none; } html { -webkit-text-size-adjust: none; } img[src*='feeds.feedburner.com'] { display: none; }"
        }
    }
}
