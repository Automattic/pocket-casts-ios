import GRDB
import PocketCastsUtils

extension PodcastDataManager {
    func setup(dbPool: DatabasePool) {
        cachePodcasts(dbPool: dbPool)
    }

    // MARK: - Caching

    private func cachePodcasts(dbPool: DatabasePool) {
        let trace = TraceManager.shared.beginTracing(eventName: "DATABASE_PODCAST_CACHE")
        defer { TraceManager.shared.endTracing(trace: trace) }

        try! dbPool.read { db in
            let rows = try Row.fetchCursor(db, sql: "SELECT * from \(DataManager.podcastTableName) ORDER BY sortOrder ASC")

            var newPodcasts = [String: Podcast]()
            while let row = try rows.next() {
                let podcast = self.createPodcastFrom(row: row)
                newPodcasts[podcast.uuid] = podcast
            }
            cachedPodcastsQueue.sync {
                cachedPodcasts = newPodcasts
            }
        }

        return
    }

    // MARK: - Conversion

    private func createPodcastFrom(row: RowCursor.Element) -> Podcast {
        Podcast.from(row: row)
    }
}
