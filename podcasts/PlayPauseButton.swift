import Lottie
import UIKit

class PlayPauseButton: BasePlayPauseButton {
    private let circleView = UIView()

    // Used to animate given LottieAnimationView doesn't animate with UIView.animate
    private var snapshot: UIView?

    private var symbolImageView: UIImageView?
    private var symbolImageIsPlaying: Bool?

    override var isPlaying: Bool {
        didSet { updateSymbolImage(animated: true) }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clear

        circleView.clipsToBounds = true
        circleView.isUserInteractionEnabled = false
        circleView.backgroundColor = circleColor
    }

    var circleColor = UIColor.white {
        didSet {
            circleView.backgroundColor = circleColor
            symbolImageView?.tintColor = circleColor
        }
    }

    /// Replaces the Lottie glyph on a solid circle with a tinted
    /// `play.circle.fill`/`pause.circle.fill` symbol. The glyph is a true
    /// cutout, and Liquid Glass renders the symbol like other tinted icons.
    func useSymbolImage(pointSize: CGFloat) {
        guard symbolImageView == nil else { return }

        circleView.isHidden = true
        animationView.isHidden = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .center
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize)
        imageView.tintColor = circleColor
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        symbolImageView = imageView
        updateSymbolImage(animated: false)
    }

    private func updateSymbolImage(animated: Bool) {
        guard let symbolImageView, symbolImageIsPlaying != isPlaying,
              let image = UIImage(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill") else { return }

        if animated, symbolImageIsPlaying != nil, UIApplication.shared.applicationState == .active {
            symbolImageView.setSymbolImage(image, contentTransition: .replace)
        } else {
            symbolImageView.image = image
        }
        symbolImageIsPlaying = isPlaying
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        circleView.layer.cornerRadius = 0.5 * circleView.bounds.width
    }

    override func place(animation: LottieAnimationView) {
        circleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleView)
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalTo: widthAnchor),
            circleView.heightAnchor.constraint(equalTo: heightAnchor),
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        animation.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animation)
        NSLayoutConstraint.activate([
            animation.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            animation.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            animation.widthAnchor.constraint(equalTo: circleView.widthAnchor, multiplier: 0.48),
            animation.heightAnchor.constraint(equalTo: circleView.heightAnchor, multiplier: 0.48)
        ])
    }

    // When using UIVIew.animate LottieAnimationView doesn't play nice with it
    // Here we snapshot the view to provide a smooth animation
    func prepareForAnimateTransition() {
        guard let snapshot = snapshotView(afterScreenUpdates: false) else { return }

        snapshot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(snapshot)
        NSLayoutConstraint.activate([
            snapshot.widthAnchor.constraint(equalTo: widthAnchor),
            snapshot.heightAnchor.constraint(equalTo: heightAnchor),
            snapshot.centerXAnchor.constraint(equalTo: centerXAnchor),
            snapshot.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.snapshot = snapshot
    }

    func finishedTransition() {
        snapshot?.removeFromSuperview()
    }
}
