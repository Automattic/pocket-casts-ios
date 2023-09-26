import SwiftUI

class RatePodcastViewModel: ObservableObject {
    @Binding var presented: Bool

    init(presented: Binding<Bool>) {
        self._presented = presented
    }
}
