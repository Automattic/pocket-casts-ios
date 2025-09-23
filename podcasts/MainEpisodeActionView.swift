import PocketCastsDataModel
import UIKit

protocol MainEpisodeActionViewDelegate: AnyObject {
    func downloadTapped()
    func stopDownloadTapped()
    func playTapped()
    func pauseTapped()
    func errorTapped()
    func waitingForWifiTapped()
}

class MainEpisodeActionView: UIView {
    enum ButtonState {
        case download, pauseDownload, play, pause, error, waitingForWifi, playedPlay, playedDownload
    }

    private static let startingAngle: CGFloat = -90
    private static let endingAngle: CGFloat = 270

    private var circleCenter: CGPoint!
    private var episodeUuid: String?

    var enlargementScale: CGFloat = 1 {
        didSet {
            setCenterPoint()
        }
    }

    var rightPadding: CGFloat = 0
    var bottomPadding: CGFloat = 0
    var playedColor: UIColor?

    weak var delegate: MainEpisodeActionViewDelegate?

    private var playedAngle: CGFloat = -90
    private var downloadAngle: CGFloat = -90

    private var state = ButtonState.download {
        didSet {
            setNeedsDisplay()
        }
    }

    init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = UIColor.clear
        tintAdjustmentMode = .normal // stops the button from being tinted grey when a VC is presented over it (like the episode card)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
        addGestureRecognizer(tapGesture)
        setCenterPoint()

        enablePointerInteraction()

        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidProgress), name: Constants.Notifications.playbackProgress, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - User Actions

    @objc private func buttonTapped() {
        guard let delegate = delegate else { return }

        if state == .play {
            delegate.playTapped()
        } else if state == .pause {
            delegate.pauseTapped()
        } else if state == .download {
            delegate.downloadTapped()
        } else if state == .pauseDownload {
            delegate.stopDownloadTapped()
        } else if state == .error {
            delegate.errorTapped()
        } else if state == .waitingForWifi {
            delegate.waitingForWifiTapped()
        }
    }

    // MARK: - Update

    func populateFrom(episode: BaseEpisode) {
        episodeUuid = episode.uuid

        let isCurrent = PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episodeUuid)

        // update download and play progress
        if episode.downloaded(pathFinder: DownloadManager.shared) {
            setDownloadProgress(1)
        } else {
            let progress = DownloadManager.shared.progressManager.progressForEpisode(episode.uuid)
            updateDownloadProgress(progress)
        }

        if episode.duration > 0 {
            let playbackProgress = episode.playedUpTo / episode.duration
            setPlaybackProgress(playbackProgress)
        } else {
            setPlaybackProgress(0)
        }

        // update button state
        let isPlaying = (isCurrent && PlaybackManager.shared.playing())
        let googleCastConnected = GoogleCastManager.sharedManager.connected()
        let primaryRowActionIsDownload = Settings.primaryRowAction() == .download
        if googleCastConnected || isCurrent {
            state = isPlaying ? .pause : .play
        } else if episode.played() {
            state = episode.downloaded(pathFinder: DownloadManager.shared) ? .playedPlay : .playedDownload
        } else if episode.playbackError() || episode.downloadFailed() {
            state = .error
        } else if isCurrent {
            state = isPlaying ? .pause : .play
        } else if primaryRowActionIsDownload, episode.downloading() || episode.queued() {
            state = .pauseDownload
        } else if episode.waitingForWifi() {
            state = .waitingForWifi
        } else if episode.downloaded(pathFinder: DownloadManager.shared) {
            state = .play
        } else {
            state = primaryRowActionIsDownload ? .download : .play
        }
    }

    // MARK: - Update Events

    @objc private func playbackDidProgress() {
        guard let playingEpisode = PlaybackManager.shared.currentEpisode(), let uuid = episodeUuid, uuid == playingEpisode.uuid else { return }

        // don't update the progress of episodes that are downloading
        if playingEpisode.downloading() { return }

        let currentTime = PlaybackManager.shared.currentTime()
        var duration = playingEpisode.duration
        let playerDuration = PlaybackManager.shared.duration()

        // just use the bigger of the two durations, being either the playable one or the one on the episode
        if playerDuration > duration {
            duration = playerDuration
        }
        if duration <= 0 { return }

        setPlaybackProgress(currentTime / duration)
    }

    func updateDownloadProgress(_ progress: DownloadProgress?) {
        let progressPercentage = progress?.progress() ?? 0

        setDownloadProgress(progressPercentage)
    }

    // MARK: - Private Helpers

    private func setPlaybackProgress(_ progress: Double) {
        playedAngle = MainEpisodeActionView.startingAngle
        if progress > 1 {
            playedAngle = 360 + MainEpisodeActionView.startingAngle
        } else if progress > 0 {
            playedAngle = CGFloat(360 * progress) + MainEpisodeActionView.startingAngle
        }
    }

    private func setDownloadProgress(_ progress: Double) {
        downloadAngle = MainEpisodeActionView.startingAngle
        if progress < 0.05 {
            downloadAngle = 18 + MainEpisodeActionView.startingAngle
        } else if progress > 1 {
            downloadAngle = 360 + MainEpisodeActionView.startingAngle
        } else if progress > 0 {
            downloadAngle = CGFloat(360 * progress) + MainEpisodeActionView.startingAngle
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        drawInContext(context, rect: rect)
    }
}

// MARK: - Drawing Code

extension MainEpisodeActionView {
    private static let circleStrokeWidth: CGFloat = 2
    private static let circleRadius: CGFloat = 14

    func setCenterPoint() {
        circleCenter = CGPoint(x: (bounds.width / 2) - rightPadding, y: (bounds.height / 2) - bottomPadding)
    }

    func drawInContext(_ context: CGContext, rect: CGRect) {
        context.clear(rect)

        switch state {
        case .pause:
            context.setLineWidth(1)

            let width = 3 * enlargementScale
            let height = 10 * enlargementScale
            let gap = width

            let startAt = circleCenter.x - width - (gap / 2.0)
            let nextAt = startAt + width + gap
            let y = circleCenter.y - (height / 2.0)
            drawPauseButton(context: context, startingX: startAt, startingY: y, width: width, height: height)
            drawPauseButton(context: context, startingX: nextAt, startingY: y, width: width, height: height)

            drawDownloadPlayingProgress(context: context)

            accessibilityLabel = L10n.podcastPausePlayback
        case .play:
            drawPlayTriangle(context: context, color: tintColor)
            drawDownloadPlayingProgress(context: context)

            accessibilityLabel = L10n.play
        case .playedPlay:
            drawImageInCenter(imageName: "list_played", color: AppTheme.episodeCellPlayedIndicatorColor())
            accessibilityLabel = L10n.statusPlayed
        case .playedDownload:
            drawImageInCenter(imageName: "list_played", color: AppTheme.episodeCellPlayedIndicatorColor())
            accessibilityLabel = L10n.statusPlayed
        case .download:
            drawDownloadArrow(context: context, color: tintColor)

            // draw the download circle, and include played progress if there is any
            context.setLineWidth(MainEpisodeActionView.circleStrokeWidth)
            if playedAngle < 270 {
                context.setStrokeColor(tintColor.cgColor)
                context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: playedAngle.degreesToRadians, endAngle: MainEpisodeActionView.endingAngle.degreesToRadians, clockwise: false)
                context.drawPath(using: .stroke)

                context.setStrokeColor(circleProgressColor().cgColor)
                context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: MainEpisodeActionView.startingAngle.degreesToRadians, endAngle: playedAngle.degreesToRadians, clockwise: false)
                context.drawPath(using: .stroke)
            } else {
                context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: MainEpisodeActionView.startingAngle.degreesToRadians, endAngle: MainEpisodeActionView.endingAngle.degreesToRadians, clockwise: false)
                context.drawPath(using: .stroke)
            }

            accessibilityLabel = L10n.download
        case .pauseDownload:
            let squareLength = 10 * enlargementScale
            let startingY = circleCenter.y - (squareLength / 2.0)
            let startingX = circleCenter.x - (squareLength / 2.0)

            context.setLineWidth(MainEpisodeActionView.circleStrokeWidth)
            context.setStrokeColor(tintColor.cgColor)

            context.move(to: CGPoint(x: startingX, y: startingY))
            context.addLine(to: CGPoint(x: startingX + squareLength, y: startingY + squareLength))
            context.strokePath()

            context.move(to: CGPoint(x: startingX, y: startingY + squareLength))
            context.addLine(to: CGPoint(x: startingX + squareLength, y: startingY))
            context.strokePath()

            // draw the download progress background
            context.setStrokeColor(circleProgressColor().cgColor)
            context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: MainEpisodeActionView.startingAngle.degreesToRadians, endAngle: MainEpisodeActionView.endingAngle.degreesToRadians, clockwise: false)
            context.drawPath(using: .stroke)

            // draw the download progress
            context.setStrokeColor(tintColor.cgColor)
            context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: MainEpisodeActionView.startingAngle.degreesToRadians, endAngle: downloadAngle.degreesToRadians, clockwise: false)
            context.drawPath(using: .stroke)

            accessibilityLabel = L10n.podcastPauseDownload
        case .waitingForWifi:
            let waitingColor = AppTheme.waitingForWifiColor()
            waitingColor.setFill()

            // draw the WiFi symbol
            let translation = CGAffineTransform(translationX: 14 - rightPadding, y: 15 + (bottomPadding / 2.0))

            let curve1 = UIBezierPath()
            curve1.move(to: CGPoint(x: 7.78, y: 0))
            curve1.addCurve(to: CGPoint(x: 0, y: 3.22), controlPoint1: CGPoint(x: 4.74, y: 0), controlPoint2: CGPoint(x: 1.99, y: 1.23))
            curve1.addLine(to: CGPoint(x: 1.42, y: 4.64))
            curve1.addCurve(to: CGPoint(x: 7.78, y: 2), controlPoint1: CGPoint(x: 3.05, y: 3.01), controlPoint2: CGPoint(x: 5.3, y: 2))
            curve1.addCurve(to: CGPoint(x: 14.14, y: 4.64), controlPoint1: CGPoint(x: 10.26, y: 2), controlPoint2: CGPoint(x: 12.51, y: 3.01))
            curve1.addLine(to: CGPoint(x: 15.56, y: 3.22))
            curve1.addCurve(to: CGPoint(x: 7.78, y: 0), controlPoint1: CGPoint(x: 13.57, y: 1.23), controlPoint2: CGPoint(x: 10.82, y: 0))
            curve1.close()
            curve1.apply(translation)
            curve1.fill()

            let curve2 = UIBezierPath()
            curve2.move(to: CGPoint(x: 2.83, y: 6.05))
            curve2.addLine(to: CGPoint(x: 4.24, y: 7.47))
            curve2.addCurve(to: CGPoint(x: 7.78, y: 6), controlPoint1: CGPoint(x: 5.15, y: 6.56), controlPoint2: CGPoint(x: 6.4, y: 6))
            curve2.addCurve(to: CGPoint(x: 11.31, y: 7.47), controlPoint1: CGPoint(x: 9.16, y: 6), controlPoint2: CGPoint(x: 10.41, y: 6.56))
            curve2.addLine(to: CGPoint(x: 12.73, y: 6.05))
            curve2.addCurve(to: CGPoint(x: 7.78, y: 4), controlPoint1: CGPoint(x: 11.46, y: 4.78), controlPoint2: CGPoint(x: 9.71, y: 4))
            curve2.addCurve(to: CGPoint(x: 2.83, y: 6.05), controlPoint1: CGPoint(x: 5.85, y: 4), controlPoint2: CGPoint(x: 4.1, y: 4.78))
            curve2.close()
            curve2.apply(translation)
            curve2.fill()

            let dot = UIBezierPath()
            dot.move(to: CGPoint(x: 5.66, y: 8.88))
            dot.addLine(to: CGPoint(x: 6.36, y: 9.59))
            dot.addLine(to: CGPoint(x: 7.07, y: 10.29))
            dot.addLine(to: CGPoint(x: 7.78, y: 11))
            dot.addLine(to: CGPoint(x: 8.48, y: 10.29))
            dot.addLine(to: CGPoint(x: 9.19, y: 9.59))
            dot.addLine(to: CGPoint(x: 9.9, y: 8.88))
            dot.addCurve(to: CGPoint(x: 7.78, y: 8), controlPoint1: CGPoint(x: 9.36, y: 8.34), controlPoint2: CGPoint(x: 8.61, y: 8))
            dot.addCurve(to: CGPoint(x: 5.66, y: 8.88), controlPoint1: CGPoint(x: 6.95, y: 8), controlPoint2: CGPoint(x: 6.2, y: 8.34))
            dot.close()
            dot.apply(translation)
            dot.fill()

            // draw the outline circle around it
            drawEmptyCircle(context: context, color: waitingColor)
            accessibilityLabel = L10n.waitForWifi
        case .error:
            let color = AppTheme.waitingForWifiColor()
            drawImageInCenter(imageName: "list_retry", color: color)
            drawEmptyCircle(context: context, color: color)
            accessibilityLabel = L10n.error
        }
    }

    private func drawImageInCenter(imageName: String, color: UIColor) {
        let image = UIImage(named: imageName)?.tintedImage(color)

        let radius = (MainEpisodeActionView.circleRadius * enlargementScale) + 1
        let drawPoint = CGPoint(x: circleCenter.x - radius, y: circleCenter.y - radius)
        image?.draw(at: drawPoint)
    }

    private func drawEmptyCircle(context: CGContext, color: UIColor) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(MainEpisodeActionView.circleStrokeWidth)
        context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: MainEpisodeActionView.startingAngle.degreesToRadians, endAngle: MainEpisodeActionView.endingAngle.degreesToRadians, clockwise: false)
        context.drawPath(using: .stroke)
    }

    private func drawDownloadPlayingProgress(context: CGContext) {
        context.setLineWidth(MainEpisodeActionView.circleStrokeWidth)
        context.setStrokeColor(circleProgressColor().cgColor)
        context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: MainEpisodeActionView.startingAngle.degreesToRadians, endAngle: playedAngle.degreesToRadians, clockwise: false)
        context.drawPath(using: .stroke)

        // at 270 degrees the episode is finished, so only draw the download circle if it's less than finished
        if playedAngle < 270 {
            context.setStrokeColor(circleProgressLeftColor().cgColor)
            context.addArc(center: circleCenter, radius: MainEpisodeActionView.circleRadius * enlargementScale, startAngle: playedAngle.degreesToRadians, endAngle: MainEpisodeActionView.endingAngle.degreesToRadians, clockwise: false)
            context.drawPath(using: .stroke)
        }
    }

    private func drawPlayTriangle(context: CGContext, color: UIColor) {
        let path = CGMutablePath()

        let playTriangleHeight = 10 * enlargementScale
        let playTriangleWidth = 9 * enlargementScale
        let startingY = circleCenter.y - (playTriangleHeight / 2.0)
        // triangles are not weighted to be visually centered, so we need to adjust the starting point to compensate for that
        let startingX = circleCenter.x - (playTriangleWidth / 2.0) + (playTriangleWidth / 6.0)
        path.move(to: CGPoint(x: startingX, y: startingY))
        path.addLine(to: CGPoint(x: startingX + playTriangleWidth, y: startingY + (playTriangleHeight / 2.0)))
        path.addLine(to: CGPoint(x: startingX, y: startingY + playTriangleHeight))
        path.addLine(to: CGPoint(x: startingX, y: startingY))
        path.closeSubpath()
        context.addPath(path)
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    private func drawDownloadArrow(context: CGContext, color: UIColor) {
        context.setLineWidth(2)
        context.setStrokeColor(color.cgColor)

        let x = 15.64 - rightPadding
        let y = 12 + (bottomPadding / 2.0)
        // arrow, taken from Paint Code
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: x + 12.72, y: y + 9.71))
        bezier2Path.addLine(to: CGPoint(x: x + 7.07, y: y + 15.36))
        bezier2Path.addLine(to: CGPoint(x: x + 6.36, y: y + 16.07))
        bezier2Path.addLine(to: CGPoint(x: x, y: y + 9.71))
        bezier2Path.addCurve(to: CGPoint(x: x, y: y + 8.29), controlPoint1: CGPoint(x: x - 0.39, y: y + 9.32), controlPoint2: CGPoint(x: x - 0.39, y: y + 8.68))
        bezier2Path.addCurve(to: CGPoint(x: x + 1.41, y: y + 8.29), controlPoint1: CGPoint(x: x + 0.39, y: y + 7.9), controlPoint2: CGPoint(x: x + 1.02, y: y + 7.9))
        bezier2Path.addLine(to: CGPoint(x: x + 5.36, y: y + 12.24))
        bezier2Path.addLine(to: CGPoint(x: x + 5.36, y: y + 1))
        bezier2Path.addCurve(to: CGPoint(x: x + 6.36, y: y), controlPoint1: CGPoint(x: x + 5.36, y: y + 0.45), controlPoint2: CGPoint(x: x + 5.81, y: y))
        bezier2Path.addCurve(to: CGPoint(x: x + 7.36, y: y + 1), controlPoint1: CGPoint(x: x + 6.91, y: y), controlPoint2: CGPoint(x: x + 7.36, y: y + 0.45))
        bezier2Path.addLine(to: CGPoint(x: x + 7.36, y: y + 12.24))
        bezier2Path.addLine(to: CGPoint(x: x + 11.31, y: y + 8.29))
        bezier2Path.addCurve(to: CGPoint(x: x + 12.72, y: y + 8.29), controlPoint1: CGPoint(x: x + 11.7, y: y + 7.9), controlPoint2: CGPoint(x: x + 12.33, y: y + 7.9))
        bezier2Path.addCurve(to: CGPoint(x: x + 12.72, y: y + 9.71), controlPoint1: CGPoint(x: x + 13.11, y: y + 8.68), controlPoint2: CGPoint(x: x + 13.11, y: y + 9.32))
        bezier2Path.close()
        bezier2Path.usesEvenOddFillRule = true
        color.setFill()
        bezier2Path.fill()
    }

    private func drawPauseButton(context: CGContext, startingX: CGFloat, startingY: CGFloat, width: CGFloat, height: CGFloat) {
        let path = CGMutablePath()

        path.move(to: CGPoint(x: startingX, y: startingY))
        path.addLine(to: CGPoint(x: startingX + width, y: startingY))
        path.addLine(to: CGPoint(x: startingX + width, y: startingY + height))
        path.addLine(to: CGPoint(x: startingX, y: startingY + height))
        path.addLine(to: CGPoint(x: startingX, y: startingY))
        path.closeSubpath()
        context.addPath(path)
        context.setFillColor(tintColor.cgColor)
        context.fillPath()
    }

    private func circleProgressColor() -> UIColor {
        tintColor.withAlphaComponent(0.3)
    }

    private func circleProgressLeftColor() -> UIColor {
        tintColor
    }
}
