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

    init(label: String, secondaryLabel: String? = nil, icon: String? = nil, selected: Bool = false, action: @escaping (() -> Void)) {
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.icon = icon
        self.action = action
        self.selected = false
    }

    init(label: String, icon: String, selected: Bool, onOffAction: Bool, action: @escaping (() -> Void)) {
        self.label = label
        self.icon = icon
        self.action = action
        self.onOffAction = onOffAction
        self.selected = selected
        secondaryLabel = nil
    }
}
