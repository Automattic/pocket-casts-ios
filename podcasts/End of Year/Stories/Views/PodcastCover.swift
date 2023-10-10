import SwiftUI
import PocketCastsServer
import Kingfisher

struct PodcastCover: View {
    /// UUID of the podcast to load the cover
    let podcastUuid: String

    /// Whether this is a big cover, in which shadows should be bigger
    var big: Bool = false

    /// The color of the view the cover will appear on
    /// Prevents a flickering issue on dark backgrounds
    var viewBackgroundStyle: ThemeStyle? = nil

    /// If the artwork needs a bigger image with higher quality
    var higherQuality: Bool = false

    @State private var image: UIImage?
    @Environment(\.renderForSharing) var renderForSharing: Bool

    private var rectangleColor: Color? {
        if let viewBackgroundStyle {
            return AppTheme.color(for: viewBackgroundStyle)
        }

        return .white
    }

    var body: some View {
        ZStack {
            Group {
                if big {
                    Rectangle()
                        .foregroundColor(rectangleColor)
                        .modifier(BigCoverShadow())
                } else {
                    Rectangle()
                        .foregroundColor(rectangleColor)
                        .modifier(NormalCoverShadow())
                }
            }
            .opacity(image != nil ? 1 : 0.2)
            .blendMode(.multiply)

            ImageView(image: image)
                .cornerRadius(big ? 8 : 4)

                .onAppear {
                    if renderForSharing {
                        loadImage()
                    }
                }

            Action {
                if !renderForSharing {
                    loadImage()
                }
            }
        }
    }

    private func loadImage() {
        image = nil
        let size = higherQuality ? 680 : 280
        KingfisherManager.shared.retrieveImage(with: ServerHelper.imageUrl(podcastUuid: podcastUuid, size: size)) { result in
            switch result {
            case .success(let result):
                image = result.image
            default:
                break
            }
        }
    }
}

/// Applies the podcast cover style to a static image
struct PodcastCoverImage: View {
    let big: Bool
    let imageName: String

    init(imageName: String, big: Bool = false) {
        self.big = big
        self.imageName = imageName
    }

    var body: some View {
        ZStack {
            Group {
                if big {
                    Rectangle()
                        .modifier(BigCoverShadow())
                } else {
                    Rectangle()
                        .modifier(NormalCoverShadow())
                }
            }

            Image(imageName)
                .resizable()
                .cornerRadius(big ? 8 : 4)
        }
    }
}

/// Apply shadow and radius to podcast cover
struct NormalCoverShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.09), radius: 3, x: 0, y: 3)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 6)
            .shadow(color: .black.opacity(0.01), radius: 4, x: 0, y: 11)
            .accessibilityHidden(true)
    }
}

/// Apply shadow and radius to podcast cover
struct BigCoverShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 9, x: 0, y: 4)
            .shadow(color: .black.opacity(0.09), radius: 17, x: 0, y: 17)
            .shadow(color: .black.opacity(0.05), radius: 23, x: 0, y: 38)
            .shadow(color: .black.opacity(0.01), radius: 27, x: 0, y: 67)
            .accessibilityHidden(true)
    }
}
