import XCTest

enum Config {
    static let promoListUUID = "297172b7-948b-4da2-9b0d-7ae9b9068125"
    static let promoList = "pktc://sharelist/lists.pocketcasts.com/\(promoListUUID)"
}

class GenerateScreenshots: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    enum Tab: Int {
        case podcasts = 0
        case filters
        case discover
        case profile
    }

    let app = XCUIApplication()
    lazy var safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

    override func setUpWithError() throws {
        continueAfterFailure = false
        setupSnapshot(app)
        app.launch()
        XCTAssert(app.wait(for: .runningForeground, timeout: 5))

        // Setup Podcast Subscription
        if requiresSetup() {
            setupSubscriptions()
        }
    }
}

// MARK: - Helpers

extension GenerateScreenshots {
    var hittablePlayButton: XCUIElement {
        return app.buttons.containing(.button, identifier: "play pause button").allElementsBoundByIndex.first(where: { $0.isHittable && $0.exists })!
    }

    var backButton: XCUIElement {
        return app.navigationBars.buttons.element(boundBy: 0)
    }

    func requiresSetup() -> Bool {
        selectTab(.podcasts)
        return app.buttons["Discover Podcasts"].exists
    }

    func setupSubscriptions() {
        // Setup Podcast subscription
        safari.launch()
        XCTAssert(safari.wait(for: .runningForeground, timeout: 5))
        safariLoad(url: Config.promoList)
        safari.buttons["Open"].waitForThenTap()

        XCTAssert(app.wait(for: .runningForeground, timeout: 5))
        app.buttons["SUBSCRIBE TO ALL"].waitForThenTap()
        app.buttons["action_0"].waitForThenTap()
    }

    func safariLoad(url: String) {
        // Setup Podcast subscription
        safari.descendants(matching: .any)["Address"].waitForThenTap()
        safari.typeText(url)
        safari.buttons["Go"].tap()
    }

    func selectTab(_ tab: Tab) {
        app.tabBars.firstMatch.buttons.element(boundBy: tab.rawValue).waitForThenTap()
    }

    func openEpisode(_ key: String) {
        app.cells.containing(NSPredicate(format: "label CONTAINS '\(key)'")).firstMatch.waitForThenTap()
    }

    func navigateToApperance() {
        selectTab(.profile)
        app.buttons["Settings"].waitForThenTap()
        app.staticTexts["appearance"].waitForThenTap()
    }

    func enableSystemThemeMatching() {
        let systemThemeToggle = app.switches["system theme toggle"]
        systemThemeToggle.expectExistence()
        if let value = systemThemeToggle.value as? String, value == "0" {
            systemThemeToggle.tap()
        }
    }

    func scrollToAndTap(_ element: XCUIElement) {
        let initialScrollPercent = app.collectionViews.scrollPercent()
        var traversedDown = initialScrollPercent == 100
        var traversedUp = initialScrollPercent == 0
        while !element.isHittable {
            if !traversedDown {
                app.swipeUp()
                traversedDown = app.collectionViews.scrollPercent() == 100
            } else if !traversedUp {
                app.swipeDown()
                traversedUp = app.collectionViews.scrollPercent() == 0
            } else {
                break
            }
        }

        element.tap()
    }
}
