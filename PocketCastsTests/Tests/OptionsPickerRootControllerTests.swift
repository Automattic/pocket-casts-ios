import PocketCastsServer
import UIKit
import XCTest

@testable import podcasts

@MainActor
final class OptionsPickerRootControllerTests: XCTestCase {
    private var originalTheme: Theme.ThemeType!

    override func setUp() {
        super.setUp()
        originalTheme = Theme.shared.activeTheme
        Theme.shared.activeTheme = .light
    }

    override func tearDown() {
        Theme.shared.activeTheme = originalTheme
        super.tearDown()
    }

    func testBackgroundFollowsThemeChange() {
        let controller = makeController()

        Theme.shared.activeTheme = .dark

        XCTAssertEqual(background(of: controller), AppTheme.optionPickerBackgroundColor(for: .dark))
    }

    func testBackgroundFollowsThemeChangeInSheetPresentation() {
        let controller = makeController()
        controller.configureForSheetPresentation()

        Theme.shared.activeTheme = .dark

        XCTAssertEqual(controller.view.backgroundColor?.withAlphaComponent(1), AppTheme.optionPickerBackgroundColor(for: .dark))
    }

    func testActionsAreNotDuplicatedByThemeChange() {
        let controller = makeController()
        let actionCount = actionViews(in: controller).count

        Theme.shared.activeTheme = .dark
        Theme.shared.activeTheme = .light

        XCTAssertEqual(actionViews(in: controller).count, actionCount)
        XCTAssertEqual(actionCount, 2)
    }

    func testThemeOverrideIsKeptOnThemeChange() {
        let controller = OptionsPickerRootController()
        controller.setup(title: nil, themeOverride: .dark, iconTintStyle: .primaryIcon01)
        controller.addAction(action: OptionAction(label: "First") {})

        Theme.shared.activeTheme = .light

        XCTAssertEqual(background(of: controller), AppTheme.optionPickerBackgroundColor(for: .dark))
    }

    private func makeController() -> OptionsPickerRootController {
        let controller = OptionsPickerRootController()
        controller.setup(title: "Title", iconTintStyle: .primaryIcon01)
        controller.addAction(action: OptionAction(label: "First") {})
        controller.addAction(action: OptionAction(label: "Second") {})
        return controller
    }

    private func background(of controller: OptionsPickerRootController) -> UIColor? {
        controller.view.subviews.compactMap { $0 as? UIScrollView }.first?.backgroundColor
    }

    private func actionViews(in controller: OptionsPickerRootController) -> [SimpleActionView] {
        controller.view.subviews
            .compactMap { $0 as? UIScrollView }
            .flatMap { $0.subviews }
            .compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .compactMap { $0 as? SimpleActionView }
    }
}
