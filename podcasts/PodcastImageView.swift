import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import Kingfisher

class PodcastImageView: UIView {
    private var shadowView: UIView?
    var imageView: UIImageView?

    /// The show artwork shrunk into the bottom-right corner once episode artwork is displayed.
    private var episodeArtworkBadge: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    func setPodcast(uuid: String, size: PodcastThumbnailSize) {
        guard let imageView else { return }
        ImageManager.sharedManager.loadImage(podcastUuid: uuid, imageView: imageView, size: size, showPlaceHolder: true)
        adjustForSize(size)
    }

    func setImageManually(image: UIImage?, size: PodcastThumbnailSize) {
        imageView?.kf.cancelDownloadTask()
        imageView?.image = image
        adjustForSize(size)
    }

    func setUserEpisode(uuid: String, size: PodcastThumbnailSize) {
        guard let imageView else { return }

        ImageManager.sharedManager.loadUserEpisodeImage(uuid: uuid, imageView: imageView, size: size, completionHandler: nil)
        adjustForSize(size)
    }

    func setBaseEpisode(episode: BaseEpisode, size: PodcastThumbnailSize) {
        guard let imageView else { return }

        ImageManager.sharedManager.loadImage(episode: episode, imageView: imageView, size: size)
        adjustForSize(size)
    }

    func setEpisodeArtwork(url: URL, size: PodcastThumbnailSize) {
        guard let imageView else { return }
        adjustForSize(size)

        let placeholder = imageView.image ?? ImageManager.sharedManager.placeHolderImage(size)
        let processor = DefaultImageProcessor.default
        imageView.kf.setImage(with: url, placeholder: placeholder, options: [
            .processor(processor),
            .transition(.fade(Constants.Animation.defaultAnimationTime)),
            .forceTransition
        ])
    }

    /// Transitions from the currently displayed show artwork to the episode artwork: the show
    /// artwork shrinks into a small rounded badge in the bottom-right corner while the episode
    /// artwork is revealed from underneath, taking the main artwork's place.
    func setEpisodeArtwork(url: URL, size: PodcastThumbnailSize, badgeBorderColor: UIColor) {
        guard let imageView else { return }
        adjustForSize(size)

        // We can only animate the show artwork into the corner if it's already on screen, and we
        // only want to run the transition once. Otherwise just fade the episode artwork in.
        guard let showArtwork = imageView.image, episodeArtworkBadge == nil else {
            setEpisodeArtwork(url: url, size: size)
            return
        }

        // Load the episode artwork up front so it's fully ready before we reveal it from under the
        // show artwork, avoiding a placeholder flashing during the animation.
        KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
            guard let self, let imageView = self.imageView, self.episodeArtworkBadge == nil,
                  case .success(let value) = result else { return }
            self.animateToEpisodeArtwork(value.image, showArtwork: showArtwork, in: imageView, badgeBorderColor: badgeBorderColor)
        }
    }

    private func animateToEpisodeArtwork(_ episodeImage: UIImage, showArtwork: UIImage, in imageView: UIImageView, badgeBorderColor: UIColor) {
        // The badge holds the show artwork and starts out exactly overlapping the main artwork, so
        // the transition begins seamlessly.
        let badge = UIImageView(image: showArtwork)
        badge.frame = bounds
        badge.contentMode = .scaleAspectFill
        badge.clipsToBounds = true
        badge.layer.cornerRadius = imageView.layer.cornerRadius
        badge.layer.cornerCurve = .continuous
        badge.layer.borderColor = badgeBorderColor.cgColor
        addSubview(badge)
        episodeArtworkBadge = badge

        // Reveal the episode artwork in the main image view (hidden under the badge for now), and
        // start it slightly scaled down so it appears to scale up into place. The scale is anchored
        // to the top-left corner so the artwork grows toward the bottom-right as the badge retreats
        // there, keeping the two motions coherent and never exposing the edges.
        imageView.image = episodeImage
        let revealScale: CGFloat = 0.92
        imageView.transform = CGAffineTransform(translationX: -bounds.width * (1 - revealScale) / 2,
                                                y: -bounds.height * (1 - revealScale) / 2)
            .scaledBy(x: revealScale, y: revealScale)

        // The badge ends as a small square in the bottom-right corner, overhanging it slightly so
        // it reads as sitting on top of the episode artwork.
        let scale: CGFloat = 0.32
        let protrusion: CGFloat = 10
        let badgeSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let finalFrame = CGRect(x: bounds.width - badgeSize.width + protrusion,
                                y: bounds.height - badgeSize.height + protrusion,
                                width: badgeSize.width,
                                height: badgeSize.height)

        let duration: TimeInterval = 0.7
        let borderWidth: CGFloat = 2
        let borderAnimation = CABasicAnimation(keyPath: "borderWidth")
        borderAnimation.fromValue = 0
        borderAnimation.toValue = borderWidth
        borderAnimation.duration = duration
        borderAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        badge.layer.borderWidth = borderWidth
        badge.layer.add(borderAnimation, forKey: "borderWidth")

        // A gently damped spring gives a smooth settle without a hard stop or noticeable bounce.
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.9) {
            badge.frame = finalFrame
            imageView.transform = .identity
        }
        animator.startAnimation()
    }

    func setTransparentNoArtwork(size: PodcastThumbnailSize) {
        imageView?.kf.cancelDownloadTask()
        imageView?.image = nil
        imageView?.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        adjustForSize(size)
    }

    func adjustForSize(_ size: PodcastThumbnailSize) {
        switch size {
        case .page:
            shadowView?.layer.shadowColor = UIColor.black.cgColor
            shadowView?.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView?.layer.shadowOpacity = 0.1
            shadowView?.layer.shadowRadius = 8
            shadowView?.layer.cornerRadius = 8

            imageView?.layer.cornerRadius = 8
        case .detail:
            shadowView?.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
            shadowView?.layer.shadowOffset = CGSize(width: 0, height: 2)
            shadowView?.layer.shadowOpacity = 1
            shadowView?.layer.shadowRadius = 10
            shadowView?.layer.cornerRadius = 8

            imageView?.layer.cornerRadius = 8
        default:
            shadowView?.layer.shadowColor = UIColor.black.cgColor
            shadowView?.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView?.layer.shadowOpacity = 0.1
            shadowView?.layer.shadowRadius = 2
            shadowView?.layer.cornerRadius = 4

            imageView?.layer.cornerRadius = 4
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let shadowView else { return }

        // the code below updates the shadow path when the view changes size. Two things to note:
        // 1. You can't not set a path. It's good for performance but also because shadowView is transparent it won't draw a shadow unless you tell it where
        // 2. The code below looks for a running animation on this view and applies the same properties to make the shadow move at the same time
        if let animation = layer.animation(forKey: "position") {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self else { return }

                shadowView.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
            }

            let pathAnimation = CABasicAnimation(keyPath: "shadowPath")
            pathAnimation.duration = animation.duration
            pathAnimation.toValue = UIBezierPath(rect: bounds).cgPath
            pathAnimation.isRemovedOnCompletion = false
            pathAnimation.timingFunction = animation.timingFunction
            pathAnimation.fillMode = CAMediaTimingFillMode.forwards
            shadowView.layer.add(pathAnimation, forKey: "shadowPath")

            CATransaction.commit()
        } else {
            shadowView.layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        }
    }

    func clearArtwork() {
        imageView?.image = ImageManager.sharedManager.placeHolderImage(.list)
    }

    private func setupView() {
        backgroundColor = UIColor.clear

        shadowView = UIView(frame: bounds)
        if let shadowView {
            shadowView.backgroundColor = UIColor.clear
            shadowView.clipsToBounds = false

            addSubview(shadowView)
            shadowView.anchorToAllSidesOf(view: self)
        }

        imageView = UIImageView(frame: bounds)
        if let imageView {
            imageView.backgroundColor = UIColor.clear
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill

            addSubview(imageView)
            imageView.anchorToAllSidesOf(view: self)
        }
    }
}
