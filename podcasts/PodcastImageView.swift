import PocketCastsDataModel
import UIKit

class PodcastImageView: UIView {
    private var shadowView: UIView?
    var imageView: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    func setPodcast(uuid: String, size: PodcastThumbnailSize) {
        guard let imageView = imageView else { return }

        ImageManager.sharedManager.loadImage(podcastUuid: uuid, imageView: imageView, size: size, showPlaceHolder: true)
        adjustForSize(size)
    }

    func setImageManually(image: UIImage?, size: PodcastThumbnailSize) {
        imageView?.image = image
        adjustForSize(size)
    }

    func setUserEpisode(uuid: String, size: PodcastThumbnailSize) {
        guard let imageView = imageView else { return }

        ImageManager.sharedManager.loadUserEpisodeImage(uuid: uuid, imageView: imageView, size: size, completionHandler: nil)
        adjustForSize(size)
    }

    func setBaseEpisode(episode: BaseEpisode, size: PodcastThumbnailSize) {
        guard let imageView = imageView else { return }

        ImageManager.sharedManager.loadImage(episode: episode, imageView: imageView, size: size)
        adjustForSize(size)
    }

    func setTransparentNoArtwork(size: PodcastThumbnailSize) {
        imageView?.kf.cancelDownloadTask()
        imageView?.image = nil
        imageView?.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        adjustForSize(size)
    }

    func adjustForSize(_ size: PodcastThumbnailSize) {
        if size == .page {
            shadowView?.layer.shadowColor = UIColor.black.cgColor
            shadowView?.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView?.layer.shadowOpacity = 0.1
            shadowView?.layer.shadowRadius = 8
            shadowView?.layer.cornerRadius = 8

            imageView?.layer.cornerRadius = 8
        } else {
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

        guard let shadowView = shadowView else { return }

        // the code below updates the shadow path when the view changes size. Two things to note:
        // 1. You can't not set a path. It's good for performance but also because shadowView is transparent it won't draw a shadow unless you tell it where
        // 2. The code below looks for a running animation on this view and applies the same properties to make the shadow move at the same time
        if let animation = layer.animation(forKey: "position") {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }

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
        if let shadowView = shadowView {
            shadowView.backgroundColor = UIColor.clear
            shadowView.clipsToBounds = false

            addSubview(shadowView)
            shadowView.anchorToAllSidesOf(view: self)
        }

        imageView = UIImageView(frame: bounds)
        if let imageView = imageView {
            imageView.backgroundColor = UIColor.clear
            imageView.clipsToBounds = true

            addSubview(imageView)
            imageView.anchorToAllSidesOf(view: self)
        }
    }
}
