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
    public static var current: BuildEnvironment {
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
