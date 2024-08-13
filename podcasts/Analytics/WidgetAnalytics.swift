import Foundation
import WidgetKit

class WidgetAnalytics {
    let userDefaults: UserDefaults
    let analytics: Analytics

    init(userDefaults: UserDefaults = UserDefaults.standard,
         analytics: Analytics = .shared) {
        self.userDefaults = userDefaults
        self.analytics = analytics
    }

    func track() {
        var widgets = userDefaults.dictionary(forKey: "installed-widgets") as? [String: Bool] ?? [String: Bool]()
        var presentWidgets: [String] = []
        WidgetCenter.shared.getCurrentConfigurations { [self] widgetInfos in
            guard case .success(let infos) = widgetInfos else { return }
            infos.forEach { widget in
                let installed = widgets["widget-\(widget.kind)-\(widget.family)"] ?? false
                presentWidgets.append("widget-\(widget.kind)-\(widget.family)")
                if !installed {
                    // Installed
                    print("$$ \(widget.kind) \(widget.family) installed")
                    widgets["widget-\(widget.kind)-\(widget.family)"] = true
                }
            }

            var unninstalledWidgets = widgets.filter { !presentWidgets.contains($0.key) }

            unninstalledWidgets.forEach { widget in
                let components = widget.key.split(separator: "-")
                print("$$ \(components[1]) \(components[2]) unninstalled")
                widgets.removeValue(forKey: widget.key)
            }

            userDefaults.set(widgets, forKey: "installed-widgets")
        }


    }
}
