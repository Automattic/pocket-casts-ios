import Foundation

public enum PodcastSorter {
    /**
     A case and accent insensitive string comparison that ignores the word "The" at the start of the title.
     - Parameter title1 String
     - Parameter title2 String
     - Returns true when title1 is alphabetically before title2, false otherwise
     */
    public static func titleSort(title1: String, title2: String) -> Bool {
        return compareTitles(title1, title2) == .orderedAscending
    }

    /**
     A comparison based on the title first. If the comparison result is the `same`, it will compare the items by `uuid`.
     - Parameter title1 String
     - Parameter title2 String
     - Returns true when title1 is alphabetically before title2, false otherwise
     */
    public static func sortByNameAndUUID(item1: Sortable, item2: Sortable) -> Bool {
        guard let title1 = item1.itemTitle, let title2 = item2.itemTitle else {
            return false
        }
        let result = compareTitles(title1, title2)
        switch result {
        case .orderedSame:
            return item1.itemUUID.compare(item2.itemUUID) == .orderedAscending
        default:
            return result == .orderedAscending
        }
    }

    private static func compareTitles(_ title1: String, _ title2: String) -> ComparisonResult {
        return title1.cleanedForTitleSort().compare(title2.cleanedForTitleSort())
    }

    /**
     A simple integer comparison function
     - Parameter order1 Int32
     - Parameter order2 Int32
     - Returns true when order2 is greater than order1, false otherwise
     */
    public static func customSort(order1: Int32, order2: Int32) -> Bool {
        return order2 > order1
    }

    /**
     A simple date comparison function
     - Parameter order1 Int32
     - Parameter order2 Int32
     - Returns true when date2 is greater than date1, false otherwise
     */
    public static func dateAddedSort(date1: Date, date2: Date) -> Bool {
        return date1.compare(date2) == .orderedAscending
    }
}

private extension String {
    /// The form of a title used for sorting: without a leading "The", lowercased and with accents removed,
    /// so that "Área" sorts with the As instead of after Z. This matches how the Android app sorts titles.
    func cleanedForTitleSort() -> String {
        let lowercasedTitle = trimmingThePrefix()
            .convertToPinyinIfNeeded()
            .localizedLowercase

        // Latin-ASCII covers both combining accents and letters like "ł", "ø" and "ß", which have none to strip
        return lowercasedTitle.applyingTransform(StringTransform("Latin-ASCII"), reverse: false) ?? lowercasedTitle
    }

    func trimmingThePrefix() -> String {
        guard let range = range(of: "^the ", options: [.regularExpression, .caseInsensitive]) else {
            return self
        }

        return String(self[range.upperBound...])
    }
}

/**
 Converts Chinese characters to their Pinyin equivalent
 - Returns Pinyin string
 */
extension String {
    func convertToPinyinIfNeeded() -> String {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try! NSRegularExpression(pattern: "[\\u4e00-\\u9fff]+")
        let hasChineseCharacter = regex.firstMatch(in: self, options: [], range: range) != nil

        if hasChineseCharacter {
            let mutableString = NSMutableString(string: self) as CFMutableString
            CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
            CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
            return mutableString as String
        } else {
            return self
        }
    }
}
