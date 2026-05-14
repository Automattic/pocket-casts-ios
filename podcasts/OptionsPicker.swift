import UIKit
import PocketCastsUtils

class OptionsPicker {
    private var title: String?
    private var window: UIWindow?
    private var optionsController: OptionsPickerRootController?

    private var noActionCallback: (() -> Void)?

    // Captured state used to rebuild the picker as a native UIAlertController
    // when `FeatureFlag.liquidGlass` is enabled. Populated alongside the legacy
    // calls to `optionsController` so call sites don't need a flag-aware branch.
    private var descriptiveTitle: String?
    private var descriptiveMessage: String?
    private var capturedActions: [OptionAction] = []

    init(title: String?, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle = .primaryIcon01, colors: OptionsPickerRootController.Colors? = nil, portraitOnly: Bool = true) {
        self.title = title
        setup(themeOverride: themeOverride, iconTintStyle: iconTintStyle, colors: colors, portraitOnly: portraitOnly)
    }

    private func setup(themeOverride: Theme.ThemeType?, iconTintStyle: ThemeStyle = .primaryIcon01, colors: OptionsPickerRootController.Colors? = nil, portraitOnly: Bool) {
        optionsController = OptionsPickerRootController()
        optionsController?.portraitOnly = portraitOnly
        optionsController?.delegate = self
        optionsController?.setup(title: title, themeOverride: themeOverride, iconTintStyle: iconTintStyle, colors: colors)
    }

    func addAction(action: OptionAction) {
        capturedActions.append(action)
        optionsController?.addAction(action: action)
    }

    func addActions(_ actions: [OptionAction]) {
        for action in actions {
            addAction(action: action)
        }
    }

    func addSegmentedAction(name: String, icon: String?, actions: [OptionAction]) {
        // Segmented actions don't have a native alert equivalent, so they're
        // tracked only for the legacy picker.
        optionsController?.addSegmentedAction(name: name, icon: icon, actions: actions)
    }

    func addDescriptiveActions(title: String, message: String?, icon: String, actions: [OptionAction]) {
        descriptiveTitle = title
        descriptiveMessage = message
        capturedActions.append(contentsOf: actions)
        optionsController?.addDescriptiveActions(title: title, message: message, icon: icon, actions: actions)
    }

    func addAttributedDescriptiveActions(title: String, message: String, icon: String, actions: [OptionAction]) {
        descriptiveTitle = title
        descriptiveMessage = message
        capturedActions.append(contentsOf: actions)
        optionsController?.addAttributedDescriptiveActions(title: title, message: message, icon: icon, actions: actions)
    }

    func setNoActionCallback(_ callback: @escaping () -> Void) {
        noActionCallback = callback
    }

    func show(statusBarStyle: UIStatusBarStyle? = nil) {
        if FeatureFlag.liquidGlass.enabled {
            presentAsNativeAlert()
        } else {
            presentAsLegacyPicker(statusBarStyle: statusBarStyle)
        }
    }

    private func presentAsLegacyPicker(statusBarStyle: UIStatusBarStyle?) {
        guard let rootController = optionsController else { return }
        #if !APPCLIP
        window = SceneHelper.newMainScreenWindow()
        #endif
        window?.rootViewController = rootController
        window?.windowLevel = UIWindow.Level.alert
        window?.makeKeyAndVisible()

        let additionalPaddingRequired: CGFloat = window?.safeAreaInsets.bottom ?? 0
        if let statusBarStyle {
            rootController.overrideStatusBarStyle = statusBarStyle
        }
        rootController.aboutToPresentOptions(bottomPadding: additionalPaddingRequired)
        rootController.animateIn()
    }

    private func presentAsNativeAlert() {
        let alert = UIAlertController(title: descriptiveTitle ?? title, message: descriptiveMessage, preferredStyle: .alert)

        for action in capturedActions {
            let style: UIAlertAction.Style = action.destructive ? .destructive : .default
            alert.addAction(UIAlertAction(title: action.label, style: style) { _ in
                action.action()
            })
        }

        let noActionCallback = self.noActionCallback
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            noActionCallback?()
        })

        #if !APPCLIP
        SceneHelper.rootViewController()?.present(alert, animated: true)
        #endif
    }

    func controllerDidAnimateOut(optionChosen: Bool) {
        if let noActionCallback, !optionChosen {
            noActionCallback()
        }

        window?.resignKey()
        window = nil
        optionsController?.delegate = nil
    }
}
