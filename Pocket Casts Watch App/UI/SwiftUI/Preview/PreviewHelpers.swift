import SwiftUI

extension PreviewDevice: Identifiable {
    public var id: String { rawValue }
    static let previewDevices = [PreviewDevice.largeWatch, PreviewDevice.smallWatch]
    static let largeWatch = PreviewDevice(rawValue: "Apple Watch Series 7 - 45mm")
    static let smallWatch = PreviewDevice(rawValue: "Apple Watch Series 5 - 40mm")
}
