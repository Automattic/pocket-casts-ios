import Foundation

class FeatureTour {
    private var tourController: TourViewController?
    private var window: UIWindow?

    var tourCompleted: (() -> Void)?

    private let tourName: String

    init(steps: [TourStep], tourName: String) {
        self.tourName = tourName
        setup(steps: steps)
    }

    func show(statusBarStyle: UIStatusBarStyle) {
        guard let rootController = tourController else { return }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootController
        window?.windowLevel = UIWindow.Level.alert
        window?.makeKeyAndVisible()

        rootController.overrideStatusBarStyle = statusBarStyle
        rootController.animateIn()

        AnalyticsHelper.tourStarted(tourName: tourName)
    }

    private func setup(steps: [TourStep]) {
        tourController = TourViewController(tourSteps: steps)
        tourController?.delegate = self
    }

    func controllerDidAnimateOut() {
        window?.resignKey()
        window = nil
        tourController?.delegate = nil
    }

    func tourCancelled(at step: Int) {
        AnalyticsHelper.tourCancelled(tourName: tourName, at: step)

        tourCompleted?()
        tourController?.animateOut()
    }

    func tourEnded() {
        AnalyticsHelper.tourCompleted(tourName: tourName)

        tourCompleted?()
        tourController?.animateOut()
    }
}
