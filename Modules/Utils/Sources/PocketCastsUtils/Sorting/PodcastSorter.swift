import Foundation

public struct PodcastSorter {
    /// TODO: Documentation
    public static func titleSort(title1: String, title2: String) -> Bool {
        let convertedTitle1 = title1.trimmingThePrefix()
        let convertedTitle2 = title2.trimmingThePrefix()

        return convertedTitle1.localizedLowercase.compare(convertedTitle2.localizedLowercase) == .orderedAscending
    }

    /// TODO: Documentation
    public static func customSort(order1: Int32, order2: Int32) -> Bool {
        return order2 > order1
    }

    /// TODO: Documentation
    public static func dateAddedSort(date1: Date, date2: Date) -> Bool {
        return date1.compare(date2) == .orderedAscending
    }
}

private extension String {
    func trimmingThePrefix() -> String {
        guard let range = range(of: "^the ", options: [.regularExpression, .caseInsensitive]) else {
            return self
        }

        return String(self[range.upperBound...])
    }
}
