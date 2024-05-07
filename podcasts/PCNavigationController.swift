import UIKit
import SwiftUI

class PCNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var navStyle: ThemeStyle = .secondaryUi01
    private var titleStyle: ThemeStyle = .secondaryText01
    private var iconStyle: ThemeStyle = .secondaryIcon01
    private var themeOverride: Theme.ThemeType?

    init(rootViewController: UIViewController, navStyle: ThemeStyle? = nil, titleStyle: ThemeStyle? = nil, iconStyle: ThemeStyle? = nil, themeOverride: Theme.ThemeType? = nil) {
        super.init(rootViewController: rootViewController)

        if let navStyle = navStyle { self.navStyle = navStyle }
        if let titleStyle = titleStyle { self.titleStyle = titleStyle }
        if let iconStyle = iconStyle { self.iconStyle = iconStyle }
        self.themeOverride = themeOverride

        updateNavColors()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(hidden, animated: animated)
        interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }

    @objc private func themeDidChange() {
        updateNavColors()
    }

    private func updateNavColors() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.colorForStyle(navStyle, themeOverride: themeOverride)
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(titleStyle, themeOverride: themeOverride)]
        appearance.shadowColor = nil

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)

        // Attempt to shrink longer text to fit in the navbar.
        let labelAppearance = UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        labelAppearance.adjustsFontSizeToFitWidth = true
        labelAppearance.minimumScaleFactor = 0.75
        labelAppearance.baselineAdjustment = .none

        // Link UserInterfaceStyle to Theme type so iOS's Increase Contrast does the right thing
        navigationBar.overrideUserInterfaceStyle = Theme.isDarkTheme() ? .dark : .light
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        // it's a little dodgy, but if the full screen player is open, always use a light tab bar
        if appDelegate()?.miniPlayer()?.playerOpenState == .open {
            return .lightContent

        // when using a navigationlink the hosting controller might be generated automatically and will apply the default status bar style
        } else if topViewController is AnyUIHostingViewController, topViewController?.preferredStatusBarStyle == .default {
            return AppTheme.defaultStatusBarStyle()
        } else {
            return topViewController?.preferredStatusBarStyle ?? AppTheme.defaultStatusBarStyle()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        topViewController?.viewWillTransition(to: size, with: coordinator)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.viewWillTransitionToSize, object: NSCoder.string(for: size))
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let topViewController = topViewController {
            return topViewController.supportedInterfaceOrientations
        }

        return .portrait // default to portrait only
    }

    // MARK: - Edge Gesture Support

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}

// MARK: - UIHostingController
/// Used so we can check if a VC is a UIHostingController
private protocol AnyUIHostingViewController: AnyObject {}
extension UIHostingController: AnyUIHostingViewController {}
