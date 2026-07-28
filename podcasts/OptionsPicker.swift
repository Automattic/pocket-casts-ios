import UIKit

class OptionsPicker {
    private var title: String?
    private var optionsController: OptionsPickerRootController?

    private var noActionCallback: (() -> Void)?

    init(title: String? = nil, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle = .primaryIcon01, colors: OptionsPickerRootController.Colors? = nil) {
        self.title = title
        setup(themeOverride: themeOverride, iconTintStyle: iconTintStyle, colors: colors)
    }

    private func setup(themeOverride: Theme.ThemeType?, iconTintStyle: ThemeStyle = .primaryIcon01, colors: OptionsPickerRootController.Colors? = nil) {
        optionsController = OptionsPickerRootController()
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

    /// Presents the options using a native, self-sizing sheet from the given
    /// view controller. The sheet's height is adjusted to fit the available
    /// options, capped at the screen height.
    func present(from presentingViewController: UIViewController) {
        guard let optionsController else { return }
        optionsController.modalPresentationStyle = .formSheet
        if let sheet = optionsController.sheetPresentationController {
            optionsController.configureForSheetPresentation()
            sheet.delegate = optionsController
            sheet.detents = [.custom { [weak optionsController] context in
                optionsController?.preferredSheetHeight(limitedTo: context.maximumDetentValue, traitCollection: context.containerTraitCollection) ?? context.maximumDetentValue
            }]
        }
        presentingViewController.present(optionsController, animated: true)
    }

    /// Presents the options as a native sheet from the app's top-most view
    /// controller. Use this when there's no obvious presenting controller at
    /// the call site.
    func present() {
        #if !APPCLIP
        guard let presenter = SceneHelper.rootViewController() else {
            // This should never happen
            assertionFailure("Unable to find a view controller to present the options picker from")
            return
        }
        present(from: presenter)
        #endif
    }

    func controllerDidAnimateOut(optionChosen: Bool) {
        if let noActionCallback, !optionChosen {
            noActionCallback()
        }

        optionsController?.delegate = nil
    }
}
