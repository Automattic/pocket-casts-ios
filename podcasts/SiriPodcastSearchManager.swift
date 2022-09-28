import Foundation
import Fuse

class SiriPodcastSearchManager {
    func matchUtteranceToPodcast(searchString: String) -> SiriPodcastItem? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId),
              let serializedPodcasts = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.siriSearchItems) as? Data else { return nil }

        do {
            let subscribedPodcasts = try JSONDecoder().decode([SiriPodcastItem].self, from: serializedPodcasts)

            guard subscribedPodcasts.count > 0 else { return nil }

            let podcastNames = subscribedPodcasts.map(\.name)

            let fuse = Fuse(location: 0, distance: 100, threshold: 0.4, maxPatternLength: 32, isCaseSensitive: false)

            var searchResults = fuse.search(searchString, in: podcastNames)
            searchResults.sort(by: { $0.score < $1.score }) // score of 0 means an exact match

            if let topMatch = searchResults.first {
                return subscribedPodcasts[topMatch.index]
            }
            return nil
        } catch {
            return nil
        }
    }
}
