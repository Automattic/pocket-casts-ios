import Foundation
#if os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

public enum DeviceUtil {
    // Gets the identifier from the system, such as "iPhone7,1"
    public static var identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)

        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()

    // The current version of the operating system (e.g. 8.4 or 9.2).
    public static var systemVersion: String? {
        #if os(watchOS)
            return WKInterfaceDevice.current().systemVersion
        #else
            return UIDevice.current.systemVersion
        #endif
    }
}
