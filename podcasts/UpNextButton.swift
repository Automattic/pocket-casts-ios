import PocketCastsDataModel
import UIKit

class UpNextButton: UIButton {
    private let numberFont = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
    private let overOneHundredNumberFont = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold)

    var iconColor: UIColor = .blue {
        didSet {
            setNeedsDisplay()
        }
    }

    var themeOverride: Theme.ThemeType?

    // MARK: - Setup

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(episodeAdded(_:)), name: Constants.Notifications.upNextEpisodeAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.upNextQueueChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(upNextChanged), name: Constants.Notifications.playbackTrackChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(episodeRemoved(_:)), name: Constants.Notifications.upNextEpisodeRemoved, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Up Next Events

    @objc private func episodeAdded(_ notification: Notification) {
        if let episodeUuid = notification.object as? String, let episode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) {
            playEpisodeAddedAnimation(episode)
        } else {
            playNumberChangeAnimation()
        }
    }

    @objc private func episodeRemoved(_ notification: Notification) {
        setNeedsDisplay()
    }

    @objc private func upNextChanged() {
        setNeedsDisplay()
    }

    @objc private func themeDidChange() {
        setNeedsDisplay()
    }

    private func playEpisodeAddedAnimation(_ episode: BaseEpisode) {
        let imageView = PodcastImageView(frame: CGRect(x: -4, y: 0, width: bounds.width, height: bounds.height))
        if let episode = episode as? Episode {
            imageView.setEpisode(episode, size: .list)
        } else {
            imageView.setUserEpisode(uuid: episode.uuid, size: .list)
        }

        addSubview(imageView)

        imageView.alpha = 0.5
        imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction], animations: {
            imageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            imageView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, delay: 0.3, options: [.allowUserInteraction], animations: {
                imageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }, completion: { _ in
                imageView.removeFromSuperview()
                self.playNumberChangeAnimation()
            })
        }
    }

    private func playNumberChangeAnimation() {
        setNeedsDisplay()
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, delay: 0, options: [.allowUserInteraction], animations: {
            self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, delay: 0, options: [.allowUserInteraction], animations: {
                self.transform = CGAffineTransform.identity
            })
        }
    }

    // MARK: - Drawing Code

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)
        let upNextCount = min(999, PlaybackManager.shared.queue.upNextCount())
        if upNextCount <= 0 {
            let bgImage = UIImage(named: "upnext")?.tintedImage(iconColor)
            let imageFrame = CGRect(x: 10, y: 10, width: 24, height: 24)

            bgImage?.draw(in: imageFrame)
        } else {
            let bgImageName: String
            if upNextCount < 10 {
                bgImageName = "icon-upnext-circle"
            } else if upNextCount < 100 {
                bgImageName = "icon-upnext-circle-wide"
            } else {
                bgImageName = "icon-upnext-circle-wide-wide"
            }
            let bgImage = UIImage(named: bgImageName)?.tintedImage(iconColor)
            let imageFrame = upNextCount < 10 ? CGRect(x: 0, y: 9, width: 36, height: 26) : CGRect(x: 0, y: 9, width: 43, height: 24)
            bgImage?.draw(in: imageFrame)

            // up next count
            let countAsStr = "\(upNextCount)" as NSString
            let textColor = isDarkTheme() ? UIColor.black : UIColor.white
            let font = upNextCount > 99 ? overOneHundredNumberFont : numberFont
            let textFontAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
            let textSize = countAsStr.size(withAttributes: textFontAttributes)
            let textPoint: CGPoint
            if upNextCount < 10 {
                textPoint = CGPoint(x: (textSize.width / 2) + 3, y: 15)
            } else if upNextCount < 100 {
                textPoint = CGPoint(x: (textSize.width / 2) - 2, y: 13)
            } else {
                textPoint = CGPoint(x: (textSize.width / 2) - 7, y: 14)
            }

            countAsStr.draw(at: textPoint, withAttributes: textFontAttributes)
        }
    }

    private func isDarkTheme() -> Bool {
        if let themeOverride = themeOverride {
            return themeOverride.isDark
        }
        return Theme.isDarkTheme()
    }
}
