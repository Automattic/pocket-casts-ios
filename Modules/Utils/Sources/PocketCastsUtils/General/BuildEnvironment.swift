import Foundation

/// Describes the type of build environment the app is running in.
/// Use `BuildEnvironment.current` to get the environment for the current running build.
public enum BuildEnvironment {
    /// From Xcode, or another DEBUG build
    case debug

    /// A release build from TestFlight
    case testFlight

    /// A release build from the AppStore
    case appStore

    /// Returns the `BuildEnvironment` for the current build
    public static var current: BuildEnvironment = .determineCurrentEnvironment

    /// Determines the current environment by:
    /// - If the DEBUG or STAGING preprocessor macros are set, return `.debug`
    /// - If the `appStoreReceiptURL` is `sandboxReceipt` return `.beta`
    /// - For anything else, return `.appStore`
    private static var determineCurrentEnvironment: BuildEnvironment {
        #if DEBUG || STAGING
        return .debug
        #else
        // https://stackoverflow.com/a/26113597/257949
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return .testFlight
        }

        return .appStore
        #endif
    }
}

extension BuildEnvironment: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .debug:
            return "debug"
        case .testFlight:
            return "testFlight"
        case .appStore:
            return "appStore"
        }
    }
}
