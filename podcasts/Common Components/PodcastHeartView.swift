import Foundation
import PocketCastsDataModel
import UIKit

class PodcastHeartView: UIView {
    var podcastColor: UIColor!
    var isShadowHidden: Bool = false {
        didSet {
            shadowView.isHidden = isShadowHidden
        }
    }

    var podcast: Podcast?
    private var lightPodcastColor = AppTheme.podcastHeartLightGradientColor()
    private var darkPodcastColor = AppTheme.podcastHeartDarkRedGradientColor()

    private var shadowView: UIView!
    private var circleView: UIView!
    var heartImageView: TintableImageView!
    private var colorGradientLayer = CAGradientLayer()
    private var greyGradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.clear

        shadowView = UIView(frame: bounds)
        shadowView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 3
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: shadowView.bounds.height / 2).cgPath
        shadowView.clipsToBounds = false
        addSubview(shadowView)

        circleView = UIView(frame: bounds)
        circleView.backgroundColor = UIColor.white
        addSubview(circleView)
        circleView.layer.cornerRadius = bounds.height / 2
        circleView.clipsToBounds = true

        if bounds.width > 50 {
            heartImageView = TintableImageView(image: UIImage(named: "supporter-heart-largest"))
        } else {
            heartImageView = TintableImageView(image: UIImage(named: "supporter-heart"))
        }
        heartImageView.backgroundColor = UIColor.clear
        heartImageView.frame = bounds
        heartImageView.tintColor = ThemeColor.contrast01()
        heartImageView.contentMode = .center
        addSubview(heartImageView)
        heartImageView.clipsToBounds = true
        heartImageView.anchorToAllSidesOf(view: self)
        updateColors()
    }

    func setPodcastColor(podcast: Podcast) {
        self.podcast = podcast
        let darkColor = ColorManager.darkThemeTintForPodcast(podcast, defaultColor: AppTheme.podcastHeartDarkRedGradientColor())
        let lightColor = ColorManager.lightThemeTintForPodcast(podcast, defaultColor: AppTheme.podcastHeartLightRedGradientColor())
        setGradientColors(light:
            lightColor, dark: darkColor)
    }

    func setGradientColors(light: UIColor, dark: UIColor) {
        lightPodcastColor = light
        darkPodcastColor = dark
        updateColors()
    }

    private func updateColors() {
        greyGradientLayer.removeFromSuperlayer()
        colorGradientLayer.removeFromSuperlayer()
        let darkGreyColor = AppTheme.podcastHeartDarkGradientColor()
        let lightGreyColor = AppTheme.podcastHeartLightGradientColor()

        greyGradientLayer.colors = [darkGreyColor.cgColor, lightGreyColor.cgColor]
        greyGradientLayer.locations = [0, 1.0]
        greyGradientLayer.startPoint = CGPoint(x: 0.75, y: 0.75)
        greyGradientLayer.endPoint = CGPoint(x: 0.25, y: 0.25)
        greyGradientLayer.frame = bounds
        greyGradientLayer.opacity = 1
        circleView.layer.addSublayer(greyGradientLayer)

        colorGradientLayer.colors = [ThemeColor.podcastOndark(podcastColor: darkPodcastColor).cgColor, ThemeColor.podcastOnlight(podcastColor: lightPodcastColor).cgColor]
        colorGradientLayer.locations = [0, 1.0]
        colorGradientLayer.startPoint = CGPoint(x: 0.25, y: 0.25)
        colorGradientLayer.endPoint = CGPoint(x: 0.75, y: 0.75)
        colorGradientLayer.frame = bounds
        colorGradientLayer.opacity = 0.75
        circleView.layer.addSublayer(colorGradientLayer)

        heartImageView.tintColor = ThemeColor.contrast01()
        bringSubviewToFront(heartImageView)
    }

    func setDefaultGreen() {
        greyGradientLayer.removeFromSuperlayer()
        colorGradientLayer.removeFromSuperlayer()
        colorGradientLayer.colors = [ThemeColor.gradient04A().cgColor, ThemeColor.gradient04E().cgColor]
        colorGradientLayer.locations = [0, 1.0]
        colorGradientLayer.startPoint = CGPoint(x: 0.25, y: 0.25)
        colorGradientLayer.endPoint = CGPoint(x: 0.75, y: 0.75)
        colorGradientLayer.frame = bounds
        colorGradientLayer.opacity = 1
        circleView.layer.addSublayer(colorGradientLayer)
        heartImageView.tintColor = ThemeColor.contrast01()
        bringSubviewToFront(heartImageView)
    }

    @objc func handleThemeDidChange() {
        updateColors()
    }
}
