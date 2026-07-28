import UIKit

protocol TourDelegate: AnyObject {
    func endTourTapped()
    func nextTapped()
}

class TourViewController: UIViewController, TourDelegate {
    private let tourSteps: [TourStep]

    var overrideStatusBarStyle = AppTheme.defaultStatusBarStyle()

    // this is not a weak var on purpose, nothing retains an FeatureTour object so we will until it dismisses
    var delegate: FeatureTour?

    private let fillLayer = CAShapeLayer()

    private let defaultTopBottomPadding: CGFloat = 120
    private let dialogPadding: CGFloat = 50

    private var topAnchor: NSLayoutConstraint!
    private var bottomAnchor: NSLayoutConstraint!

    private lazy var tourView: TourView = {
        let tourView = TourView(stepCount: tourSteps.count)
        tourView.delegate = self
        tourView.translatesAutoresizingMaskIntoConstraints = false

        return tourView
    }()

    private var upToStep = 0

    init(tourSteps: [TourStep]) {
        self.tourSteps = tourSteps

        super.init(nibName: "TourViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private var haveSetupView = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !haveSetupView {
            haveSetupView = true
            setup()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if fillLayer.path?.boundingBox.maxY != view.bounds.maxY, upToStep == 0 {
            fillLayer.path = UIBezierPath(rect: view.bounds).cgPath
        }
    }

    private func setup() {
        guard let firstStep = tourSteps.first else { return }

        view.layoutIfNeeded()
        view.backgroundColor = UIColor.clear

        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(fillLayer)
        fillLayer.path = UIBezierPath(rect: view.bounds).cgPath

        view.addSubview(tourView)
        if view.bounds.width > 530 {
            // for large widths, used a fixed size dialog
            NSLayoutConstraint.activate([
                tourView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 14),
                view.trailingAnchor.constraint(greaterThanOrEqualTo: tourView.trailingAnchor, constant: 14),
                tourView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                tourView.widthAnchor.constraint(equalToConstant: 500)
            ])
        } else {
            // for smaller more phone sized views use a fixed padding from the edge
            NSLayoutConstraint.activate([
                tourView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
                view.trailingAnchor.constraint(equalTo: tourView.trailingAnchor, constant: 14)
            ])
        }

        bottomAnchor = view.bottomAnchor.constraint(equalTo: tourView.bottomAnchor, constant: defaultTopBottomPadding)
        topAnchor = tourView.topAnchor.constraint(equalTo: view.topAnchor, constant: defaultTopBottomPadding)
        bottomAnchor.isActive = true

        displayStep(step: firstStep)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        overrideStatusBarStyle
    }

    // MARK: - TourDelegate

    func endTourTapped() {
        if upToStep < tourSteps.count - 1 {
            // user cancelled early
            delegate?.tourCancelled(at: upToStep)
        } else {
            // user got all the way through
            delegate?.tourEnded()
        }
    }

    func nextTapped() {
        if upToStep == tourSteps.count - 1 {
            // we're at the last step, the tour is over
            delegate?.tourEnded()
        } else {
            proceedToNextStep()
        }
    }

    private func proceedToNextStep() {
        upToStep += 1

        let step = tourSteps[upToStep]

        displayStep(step: step)
    }

    private func displayStep(step: TourStep) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            if let highlightView = step.featureHighlight, let superview = highlightView.superview {
                var itemRect = superview.convert(highlightView.frame, to: self.view)
                itemRect.origin.y += step.yTranslation

                if step.anchorToTop {
                    self.topAnchor.constant = itemRect.maxY + self.dialogPadding
                } else {
                    self.bottomAnchor.constant = self.view.frame.height - itemRect.minY + self.dialogPadding
                }
            } else if let spotlight = step.spotlight {
                let itemCenter = spotlight.superview.convert(spotlight.center, to: self.view)
                var itemRect = CGRect(origin: CGPoint(x: itemCenter.x - spotlight.radius, y: itemCenter.y - spotlight.radius), size: CGSize(width: spotlight.radius, height: spotlight.radius))
                itemRect.origin.y += step.yTranslation

                if step.anchorToTop {
                    self.topAnchor.constant = itemRect.maxY + self.dialogPadding
                } else {
                    self.bottomAnchor.constant = self.view.frame.height - itemRect.minY + self.dialogPadding
                }
            } else {
                self.topAnchor.constant = self.defaultTopBottomPadding
                self.bottomAnchor.constant = self.defaultTopBottomPadding
            }

            self.topAnchor.isActive = step.anchorToTop
            self.bottomAnchor.isActive = !step.anchorToTop
            self.view.layoutIfNeeded()
        }

        tourView.position = upToStep
        tourView.step = step

        updateCutOut(step: step, animated: upToStep > 1)
    }

    private func updateCutOut(step: TourStep, animated: Bool) {
        let path = UIBezierPath(rect: view.bounds)

        if let highlightView = step.featureHighlight, let superview = highlightView.superview {
            var itemRect = superview.convert(highlightView.frame, to: view)
            itemRect.origin.y += step.yTranslation
            if itemRect.width < 80 {
                // for small items draw a circle
                let cutoutRect = itemRect.insetBy(dx: -20, dy: -20)
                let cutOutPath = UIBezierPath(roundedRect: cutoutRect, cornerRadius: 40)
                path.append(cutOutPath)
            } else {
                // for bigger items draw a rounded rect
                let cutoutRect = itemRect.insetBy(dx: -20, dy: 0)
                let cutOutPath = UIBezierPath(roundedRect: cutoutRect, cornerRadius: 40)
                path.append(cutOutPath)
            }

            path.usesEvenOddFillRule = true
        } else if let spotlight = step.spotlight {
            let spotlightCenter = spotlight.superview.convert(spotlight.center, to: view)

            let cutOutPath = UIBezierPath(arcCenter: spotlightCenter, radius: spotlight.radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
            path.append(cutOutPath)
        }
        if !animated || step.featureHighlight == nil || step.spotlight == nil {
            fillLayer.path = path.cgPath
            fillLayer.removeAllAnimations()
            return
        }

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.fillLayer.path = path.cgPath
        }

        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = fillLayer.path
        pathAnimation.toValue = path.cgPath
        pathAnimation.duration = Constants.Animation.defaultAnimationTime
        pathAnimation.fillMode = .forwards
        pathAnimation.isRemovedOnCompletion = false
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fillLayer.add(pathAnimation, forKey: "path")

        CATransaction.commit()
    }

    // MARK: - Animate In/Out

    func animateIn() {
        view.alpha = 0
        view.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            self?.view.alpha = 1

            self?.view?.layoutIfNeeded()
        }, completion: nil)
    }

    func animateOut() {
        view?.layoutIfNeeded()
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: { [weak self] in
            self?.view.alpha = 0

            self?.view?.layoutIfNeeded()
        }) { [weak self] _ in
            self?.delegate?.controllerDidAnimateOut()
        }
    }
}
