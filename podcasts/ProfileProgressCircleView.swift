import UIKit
import Kingfisher
import PocketCastsServer

class ProfileProgressCircleView: ThemeableView {
    var isSubscribed = false {
        didSet {
            if isSubscribed {
                profileImageView.image = UIImage(named: "plusAvatar")
                profileImageView.tintColor = AppTheme.colorForStyle(.primaryUi01)
                profileGradientView.backgroundColor = UIColor.clear
                layer.addSublayer(expiryGradientLayer)
                profileGradientView.layer.insertSublayer(profileGradientLayer, at: 0)
            } else {
                profileImageView.image = UIImage(named: "profileAvatar")
                profileGradientView.backgroundColor = ThemeColor.primaryUi05()
                expiryShapeLayer?.removeFromSuperlayer()
                expiryGradientLayer?.removeFromSuperlayer()
                profileGradientLayer?.removeFromSuperlayer()
            }
            setNeedsDisplay()
        }
    }

    var secondsTillExpiry = Constants.Limits.maxSubscriptionExpirySeconds {
        didSet {
            let percent: Double
            if secondsTillExpiry < 0 {
                percent = 0
            } else {
                percent = min(1, secondsTillExpiry / Constants.Limits.maxSubscriptionExpirySeconds)
            }
            let percentageLeft = 1 - percent
            startingAngle = CGFloat((percentageLeft * 360) - 90)
        }
    }

    private var startingAngle: CGFloat = -90 {
        didSet {
            setNeedsDisplay()
        }
    }

    private var endingAngle: CGFloat = 270 {
        didSet {
            setNeedsDisplay()
        }
    }

    private var gravatarImageView: UIImageView!
    private var profileImageView: UIImageView!
    private var profileGradientView: UIView!
    private var profileGradientLayer: CAGradientLayer!
    private var expiryGradientLayer: CAGradientLayer!
    private var expiryShapeLayer: CAShapeLayer!

    private var lineWidth: CGFloat = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        gravatarImageView = UIImageView()
        profileImageView = UIImageView()
        profileGradientView = UIView()
        addSubview(profileGradientView)
        addSubview(profileImageView)
        addSubview(gravatarImageView)

        profileGradientLayer = CAGradientLayer()
        profileGradientLayer.colors = [ThemeColor.gradient01A().cgColor, ThemeColor.gradient01E().cgColor]
        profileGradientLayer.locations = [0.0, 1.0]
        profileGradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        profileGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        expiryGradientLayer = CAGradientLayer()
        expiryGradientLayer.colors = [ThemeColor.gradient01E().cgColor, ThemeColor.gradient01A().cgColor]

        expiryShapeLayer = CAShapeLayer()
        expiryShapeLayer.lineWidth = lineWidth
        expiryShapeLayer.strokeColor = ThemeColor.gradient01E().cgColor

        let imageSize = frame.size.width - (4 * lineWidth)
        let origin = 2 * lineWidth
        profileImageView.frame = CGRect(x: origin, y: origin, width: imageSize, height: imageSize)
        profileGradientView.frame = CGRect(x: origin, y: origin, width: imageSize, height: imageSize)
        profileGradientView.layer.cornerRadius = imageSize / 2

        profileGradientLayer.frame = CGRect(x: 0, y: 0, width: imageSize, height: imageSize)
        profileGradientLayer.cornerRadius = imageSize / 2

        expiryGradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        expiryShapeLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)

        gravatarImageView.frame = CGRect(x: origin, y: origin, width: imageSize, height: imageSize)

        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatar), name: .userLoginDidChange, object: nil)
        updateAvatar()
    }

    override func draw(_ rect: CGRect) {
        if isSubscribed {
            let path = UIBezierPath()

            let radius = (rect.width / 2) - 1.5
            path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: startingAngle.degreesToRadians, endAngle: endingAngle.degreesToRadians, clockwise: true)
            expiryShapeLayer.fillColor = UIColor.clear.cgColor
            expiryShapeLayer.path = path.cgPath
            expiryGradientLayer.mask = expiryShapeLayer
        }
    }

    override func handleThemeDidChange() {
        profileImageView.tintColor = ThemeColor.primaryUi01()
        profileGradientView.backgroundColor = ThemeColor.primaryUi05()
        profileGradientLayer.colors = [ThemeColor.gradient01A().cgColor, ThemeColor.gradient01E().cgColor]
        expiryGradientLayer.colors = [ThemeColor.gradient01A().cgColor, ThemeColor.gradient01E().cgColor]
    }

    @objc private func updateAvatar() {
        if let email = ServerSettings.syncingEmail() {
            let gravatarSize = frame.size.width * UIScreen.main.scale
            let imageSize = gravatarSize - (4 * lineWidth)
            let gravatar = "https://www.gravatar.com/avatar/\(email.md5)?d=404&s=\(gravatarSize)"
            let processor = RoundCornerImageProcessor(cornerRadius: imageSize)
            let options: KingfisherOptionsInfo = [
                .processor(processor), // rounder corners
                .cacheSerializer(FormatIndicatedCacheSerializer.png) // convert to a png
            ]

            gravatarImageView.kf.setImage(with: URL(string: gravatar), placeholder: nil, options: options)
        } else {
            gravatarImageView.image = nil
        }
    }
}
