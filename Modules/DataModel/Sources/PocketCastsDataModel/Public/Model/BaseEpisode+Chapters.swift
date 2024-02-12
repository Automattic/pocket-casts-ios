import Foundation

extension BaseEpisode {
    private var deselectedChaptersList: [String.SubSequence] {
        deselectedChapters?.split(separator: ",") ?? []
    }

    public func select(chapterIndex index: Int) {
        guard let elementIndex = deselectedChaptersList.firstIndex(of: "\(index)") else {
            return
        }

        var deselectedChaptersList = deselectedChaptersList
        deselectedChaptersList.remove(at: elementIndex)
        deselectedChapters = deselectedChaptersList.joined(separator: ",")
    }

    public func deselect(chapterIndex index: Int) {
        let chapters = deselectedChaptersList + ["\(index)"]
        deselectedChapters = chapters.joined(separator: ",")
    }
}
