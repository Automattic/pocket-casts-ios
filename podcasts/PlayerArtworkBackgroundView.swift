import CoreImage
import PocketCastsDataModel
import UIKit

/// The large screen player background: the blurred and scaled up artwork, under a layer of the
/// player's dark artwork-based color at 70% opacity.
final class PlayerArtworkBackgroundView: UIView {
    private let artworkView = UIImageView()
    private let tintView = UIView()
    private var artworkEpisodeUuid: String?

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        clipsToBounds = true

        artworkView.contentMode = .scaleAspectFill
        artworkView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(artworkView)

        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        NSLayoutConstraint.activate([
            artworkView.centerXAnchor.constraint(equalTo: centerXAnchor),
            artworkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            artworkView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.5),
            artworkView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.5)
        ])
        tintView.anchorToAllSidesOf(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(episode: BaseEpisode?, tintColor: UIColor) {
        backgroundColor = tintColor
        tintView.backgroundColor = tintColor.withAlphaComponent(0.7)

        if episode?.uuid != artworkEpisodeUuid {
            reloadArtwork(for: episode)
        }
    }

    func reloadArtwork(for episode: BaseEpisode?) {
        artworkEpisodeUuid = episode?.uuid
        guard let episode else {
            artworkView.image = nil
            return
        }

        let episodeUuid = episode.uuid
        ImageManager.shared.image(for: episode, size: .page) { [weak self] image in
            guard let image else { return }

            DispatchQueue.global(qos: .userInitiated).async {
                let blurredImage = PlayerArtworkBlur.blurredImage(from: image)
                DispatchQueue.main.async {
                    guard let self, self.artworkEpisodeUuid == episodeUuid else { return }

                    UIView.transition(with: self.artworkView, duration: 0.3, options: .transitionCrossDissolve) {
                        self.artworkView.image = blurredImage
                    }
                }
            }
        }
    }
}

private enum PlayerArtworkBlur {
    static let context = CIContext()

    /// Blurs a small copy of the image: it's scaled up to fill the screen anyway.
    static func blurredImage(from image: UIImage) -> UIImage? {
        guard let input = CIImage(image: image), input.extent.width > 0, input.extent.height > 0 else { return nil }

        let scale = 64 / max(input.extent.width, input.extent.height)
        let downscaled = input.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let blurred = downscaled.clampedToExtent()
            .applyingGaussianBlur(sigma: 6)
            .cropped(to: downscaled.extent)

        guard let cgImage = context.createCGImage(blurred, from: downscaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
