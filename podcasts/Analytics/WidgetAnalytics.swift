import Foundation
import WidgetKit

class WidgetAnalytics {
    private let userDefaults: UserDefaults
    private let analytics: Analytics

    init(userDefaults: UserDefaults = UserDefaults.standard,
         analytics: Analytics = .shared) {
        self.userDefaults = userDefaults
        self.analytics = analytics
    }

    func track() {
        var previousWidgets = userDefaults.dictionary(forKey: "installed-widgets") as? [String: Bool] ?? [String: Bool]()
        var currentWidgets: [String] = []

        WidgetCenter.shared.getCurrentConfigurations { [self] widgetInfos in
            guard case .success(let infos) = widgetInfos else { return }

            // Track installed widgets
            infos.forEach { widget in
                let installed = previousWidgets[widgetKey(widget)] ?? false
                currentWidgets.append(widgetKey(widget))
                if !installed {
                    // Installed
                    print("$$ \(widget.kind) \(widget.family) installed")
                    previousWidgets[widgetKey(widget)] = true
                }
            }

            // Track unninstalled widgets
            let unninstalledWidgets = previousWidgets.filter { !currentWidgets.contains($0.key) }
            unninstalledWidgets.forEach { widget in
                let components = widget.key.split(separator: "$")
                if let kind = components[safe: 1], let family = components[safe: 2] {
                    print("$$ \(kind) \(family) unninstalled")
                }
                previousWidgets.removeValue(forKey: widget.key)
            }

            userDefaults.set(previousWidgets, forKey: "installed-widgets")
        }
    }

    private func widgetKey(_ widget: WidgetInfo) -> String {
        return "widget$\(widget.kind)$\(widget.family)"
    }
}
