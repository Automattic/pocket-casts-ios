import SwiftUI

extension View {
    /// Generate the SwiftUI Preview with a specific theme
    func preview(with theme: Theme.ThemeType) -> some View {
        modifier(PocketCastsPreviewer(themes: [theme]))
    }

    /// Generate multiple SwiftUI previews for multiple themes
    func preview(with themes: [Theme.ThemeType]) -> some View {
        modifier(PocketCastsPreviewer(themes: themes))
    }

    /// Generate the SwiftUI preview with the specific device and theme (light by default)
    func preview(on device: PCPreviewDevice, with theme: Theme.ThemeType = .light) -> some View {
        modifier(PocketCastsPreviewer(themes: [theme], devices: [device]))
    }

    /// Generate multiple SwiftUI previews for all the Pocket Cast themes
    func previewWithAllThemes() -> some View {
        modifier(PocketCastsPreviewer.allThemes())
    }

    /// Generate multiple SwiftUI previews for the common device sizes to test on, and the specified theme (light by default)
    func previewOnAllDevices(with theme: Theme.ThemeType = .light) -> some View {
        modifier(PocketCastsPreviewer.allDevices(with: theme))
    }
}

// MARK: - Preview View Modifier

private struct PocketCastsPreviewer: ViewModifier {
    static func allThemes(with devices: [PCPreviewDevice]? = nil) -> PocketCastsPreviewer {
        PocketCastsPreviewer(themes: Theme.ThemeType.allCases, devices: devices)
    }

    static func allDevices(with theme: Theme.ThemeType) -> PocketCastsPreviewer {
        PocketCastsPreviewer(themes: [theme], devices: PCPreviewDevice.allCases)
    }

    private let themes: [Theme.ThemeType]
    private let devices: [PCPreviewDevice]?

    init(themes: [Theme.ThemeType]? = nil, devices: [PCPreviewDevice]? = nil) {
        self.themes = themes ?? [.light]
        self.devices = devices
    }

    func body(content: Content) -> some View {
        ForEach(themes, id: \.self) { themeType in
            let theme = Theme(previewTheme: themeType)

            // If there's devices specifier, then generate a preview for each theme and rename them
            if let devices {
                ForEach(devices) { device in
                    content
                        .environmentObject(theme)
                        .previewDisplayName(device.name + " - " + themeType.description)
                        .previewDevice(device.previewDevice)
                }
            // If there's just a theme, then render that.
            } else {
                content
                    .environmentObject(theme)
                    .previewDisplayName(themeType.description)
            }
        }
    }
}

// MARK: - Enum to define the common devices we test on
enum PCPreviewDevice: String, CaseIterable, Identifiable {
    // An invalid value passed to PreviewDevice returns the current device, so use that to make the current one
    case current = ""
    case iPhone8 = "iPhone 8"
    case iPhone14ProMax = "iPhone 14 Pro Max"
    case iPhoneSE = "iPhone SE (3rd generation)"

    var name: String { rawValue.isEmpty ? "Current" : rawValue }

    var previewDevice: PreviewDevice { PreviewDevice(rawValue: rawValue) }
    var id: String { rawValue }
}
