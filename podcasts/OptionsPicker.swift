import UIKit

class OptionsPicker {
    private var title: String?
    private var window: UIWindow?
    private var optionsController: OptionsPickerRootController?

    private var noActionCallback: (() -> Void)?

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
        optionsController?.addAction(action: action)
    }

    func addActions(_ actions: [OptionAction]) {
        for action in actions {
            addAction(action: action)
        }
    }

    func addSegmentedAction(name: String, icon: String?, actions: [OptionAction]) {
        optionsController?.addSegmentedAction(name: name, icon: icon, actions: actions)
    }

    func addDescriptiveActions(title: String, message: String?, icon: String, actions: [OptionAction]) {
        optionsController?.addDescriptiveActions(title: title, message: message, icon: icon, actions: actions)
    }

    func addAttributedDescriptiveActions(title: String, message: String, icon: String, actions: [OptionAction]) {
        optionsController?.addAttributedDescriptiveActions(title: title, message: message, icon: icon, actions: actions)
    }

    func setNoActionCallback(_ callback: @escaping () -> Void) {
        noActionCallback = callback
    }

    func show(statusBarStyle: UIStatusBarStyle? = nil) {
        guard let rootController = optionsController else { return }
        //TODO: Figure this out and fix it
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

    func controllerDidAnimateOut(optionChosen: Bool) {
        if let noActionCallback = noActionCallback, !optionChosen {
            noActionCallback()
        }

        window?.resignKey()
        window = nil
        optionsController?.delegate = nil
    }
}
