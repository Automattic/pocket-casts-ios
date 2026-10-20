@testable import podcasts
import XCTest

@MainActor
final class NewPlaylistViewControllerThemeTests: XCTestCase {
    private var originalTheme: Theme.ThemeType!

    override func setUp() {
        super.setUp()
        originalTheme = Theme.shared.activeTheme
    }

    override func tearDown() {
        Theme.shared.activeTheme = originalTheme
        super.tearDown()
    }

    func testBackgroundFollowsThemeChange() {
        Theme.shared.activeTheme = .light
        let controller = NewPlaylistViewController()
        controller.loadViewIfNeeded()
        XCTAssertEqual(controller.view.backgroundColor, AppTheme.viewBackgroundColor)

        Theme.shared.activeTheme = .dark

        XCTAssertEqual(controller.view.backgroundColor, AppTheme.viewBackgroundColor)
    }
}
