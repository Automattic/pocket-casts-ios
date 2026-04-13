import XCTest
import PocketCastsDependencyInjection
@testable import PocketCastsDependencyInjection

final class DependencyInjectionTests: XCTestCase {
    @Dependency(container: TestDependencyContainer.current, \.mockSingleton)
    var mockSingleton: MockSingleton

    func testMockSingleton() throws {
        XCTAssertEqual(mockSingleton.name, "default")

        TestDependencyContainer[\.mockSingleton] = MockSingleton(name: "new")

        XCTAssertEqual(mockSingleton.name, "new")
    }
}

struct MockSingleton {
    let name: String
}

struct MockSingletonKey: DependencyKey {
    static var currentValue = MockSingleton(name: "default")
}

extension TestDependencyContainer {
    var mockSingleton: MockSingleton {
        get { Self[MockSingletonKey.self] }
        set { Self[MockSingletonKey.self] = newValue }
    }
}
