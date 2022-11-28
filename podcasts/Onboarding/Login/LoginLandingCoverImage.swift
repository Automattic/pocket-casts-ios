import SwiftUI
import Kingfisher
import PocketCastsServer

struct LoginLandingCoverImage: View {
    /// UUID of the podcast to load the cover
    let podcastUuid: String

    /// The color of the view the cover will appear on
    /// Prevents a flickering issue on dark backgrounds
    let viewBackgroundStyle: ThemeStyle?

    private let image: UIImage

    init(podcastUuid: String, viewBackgroundStyle: ThemeStyle? = nil, placeholderImage: String) {
        self.podcastUuid = podcastUuid
        self.viewBackgroundStyle = viewBackgroundStyle

        let cachedImage = ImageManager.sharedManager.cachedImageFor(podcastUuid: podcastUuid, size: .grid)

        if let cachedImage {
            self.image = cachedImage
        } else if let image = UIImage(named: placeholderImage) {
            self.image = image
        } else {
            self.image = UIImage()
        }
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .cornerRadius(8)
            .modifier(BigCoverShadow())
    }
}
