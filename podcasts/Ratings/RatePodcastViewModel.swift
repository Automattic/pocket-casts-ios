import SwiftUI

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    var podcastUuid: String

    init(presented: Binding<Bool>, podcastUuid: String) {
        self._presented = presented
        self.podcastUuid = podcastUuid
    }
}
