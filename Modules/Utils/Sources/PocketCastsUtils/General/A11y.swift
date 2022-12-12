import UIKit

public struct A11y {
    #if os(iOS)
    public static var isDisplayZoomed: Bool {
        UIScreen.main.nativeScale > UIScreen.main.scale
    }
    #endif
}
