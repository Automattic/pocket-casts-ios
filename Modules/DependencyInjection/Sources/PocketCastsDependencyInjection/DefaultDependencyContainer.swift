import Foundation

public struct DefaultDependencyContainer: DependencyContainer {
    public static var current = DefaultDependencyContainer()

    private init() { }
}
