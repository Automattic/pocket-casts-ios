import Foundation

extension Podcast {
    public var podcastSortOrder: PodcastEpisodeSortOrder? {
        PodcastEpisodeSortOrder(old: PodcastEpisodeSortOrder.Old(rawValue: episodeSortOrder) ?? .newestToOldest)
    }
}
