import SwiftUI
import WidgetKit

extension View {
    @ViewBuilder
    func backwardWidgetAccentable(_ accentable: Bool = true) -> some View {
        self.widgetAccentable(accentable)
    }
}

extension Image {
    @ViewBuilder
    func backwardWidgetAccentedRenderingMode(_ isAccentedRenderingMode: Bool = true) -> some View {
        if #available(iOS 18.0, *) {
            self.widgetAccentedRenderingMode(isAccentedRenderingMode ? .accented : .fullColor)
        }
        else {
            self
        }
    }

    @ViewBuilder
    func backwardWidgetAccentedDesaturatedRenderingMode() -> some View {
        if #available(iOS 18.0, *) {
            self.widgetAccentedRenderingMode(.accentedDesaturated)
        }
        else {
            self
        }
    }

    @ViewBuilder
    func backwardWidgetFullColorRenderingMode() -> some View {
        backwardWidgetAccentedRenderingMode(false)
    }
}

extension EnvironmentValues {
    var isAccentedRenderingMode: Bool {
        get {
            widgetRenderingMode == .accented
        }
    }
}

private enum AccentedWidgetKey: EnvironmentKey {
    static let defaultValue = false
}
