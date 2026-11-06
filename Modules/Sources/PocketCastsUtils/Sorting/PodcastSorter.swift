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
        let convertedTitle1 = title1.trimmingThePrefix().convertToPinyinIfNeeded()
        let convertedTitle2 = title2.trimmingThePrefix().convertToPinyinIfNeeded()

        // Ignoring accents keeps a title like "Área" with the As instead of after Z
        return convertedTitle1.compare(convertedTitle2, options: [.caseInsensitive, .diacriticInsensitive])
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
    func trimmingThePrefix() -> String {
        prefix(4).lowercased() == "the " ? String(dropFirst(4)) : self
    }
}

/**
 Converts Chinese characters to their Pinyin equivalent
 - Returns Pinyin string
 */
extension String {
    private static let pinyinCache = Mutex([String: String]())

    func convertToPinyinIfNeeded() -> String {
        guard unicodeScalars.contains(where: { (0x4E00...0x9FFF).contains($0.value) }) else {
            return self
        }
        if let pinyin = Self.pinyinCache.withLock({ $0[self] }) {
            return pinyin
        }

        let mutableString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        let pinyin = mutableString as String
        Self.pinyinCache.withLock { $0[self] = pinyin }
        return pinyin
    }
}
