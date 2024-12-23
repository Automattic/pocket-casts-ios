import GRDB

extension PodcastDataManager {
    // MARK: - Conversion

    private func createPodcastFrom(row: RowCursor.Element) -> Podcast {
        Podcast.from(row: row)
    }
}
