import SwiftUI

struct SlumberWhatsNewHeader: View {
    var body: some View {
        HStack {
            Group {
                PodcastCover(podcastUuid: "82e37e80-755d-0138-eddc-0acc26574db2")
                PodcastCover(podcastUuid: "9478cc80-7c42-0138-edfe-0acc26574db2")
                PodcastCover(podcastUuid: "37082d70-e945-0137-b6eb-0acc26574db2")
                PodcastCover(podcastUuid: "62200ab0-b7ec-0139-f606-0acc26574db2")

            }
                .frame(width: 120, height: 120)
        }
            .environment(\.renderForSharing, false)
    }
}

#Preview {
    SlumberWhatsNewHeader()
}
