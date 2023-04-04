import SwiftUI
import Kingfisher
import PocketCastsServer

struct PodcastImage: View {
    let uuid: String
    let size: Int

    init(uuid: String, size: Int = 280) {
        self.uuid = uuid
        self.size = size
    }

    var body: some View {
        KFImage(ServerHelper.imageUrl(podcastUuid: uuid, size: size))
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}
