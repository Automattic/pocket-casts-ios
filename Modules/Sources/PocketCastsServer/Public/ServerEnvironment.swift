import Foundation

public enum ServerEnvironment: String, CaseIterable {
    case production
    case staging

    /// The server every request goes to. Each app sets it at launch, before it makes any request.
    public static var current: ServerEnvironment = .production
}
