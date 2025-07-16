import Foundation
import PocketCastsDependencyInjection

struct TestDependencyContainer: DependencyContainer {
    static var current = TestDependencyContainer()

    private init() { }
}
