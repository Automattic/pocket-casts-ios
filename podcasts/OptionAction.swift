import Foundation

class OptionAction {
    let label: String
    let secondaryLabel: String?
    let icon: String?
    let action: () -> Void
    let selected: Bool
    var destructive = false
    var outline = false
    var onOffAction = false
    var tintIcon: Bool = true
    /// When set, tapping the action presents the returned picker as a submenu
    /// on top of the current one. Choosing an option in the submenu dismisses
    /// both. The closure is evaluated lazily, only when the action is tapped.
    var submenu: (() -> OptionsPicker?)?

    init(label: String, secondaryLabel: String? = nil, icon: String? = nil, tintIcon: Bool = true, selected: Bool = false, action: @escaping (() -> Void)) {
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.icon = icon
        self.tintIcon = tintIcon
        self.action = action
        self.selected = selected
    }

    init(label: String, icon: String, tintIcon: Bool = true, selected: Bool, onOffAction: Bool, action: @escaping (() -> Void)) {
        self.label = label
        self.icon = icon
        self.tintIcon = tintIcon
        self.action = action
        self.onOffAction = onOffAction
        self.selected = selected
        secondaryLabel = nil
    }
}
