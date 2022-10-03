import XCTest

private extension Config {
    static let step_02_podcastName = "American Fiasco"
    static let step_02_episodeKey = "Bonus Episode with Stephen Dubner"
    static let step_02_multiTaskURL = "https://en.wikipedia.org/wiki/History_of_soccer_in_the_United_States"
    static let step_03_podcastName = "Making"
    static let step_03_episodeKey = "Beyoncé 3: Destiny Begins"
    static let step_03_multiTaskURL = "https://www.biography.com/musician/beyonce-knowles"
    static let step_04_podcastName = "All In The Mind"
}

class iPad_GenerateScreenshots: GenerateScreenshots {
    func test_generateScreenshots() throws {
        // 01 - Podcast List (Default Light Theme)
        selectTab(.podcasts)
        snapshot("01_Podcast_List")

        // 02 - Episode Details with Multi-Task (Landscape)
        XCUIDevice.shared.orientation = .landscapeLeft
        startMultiTask(withURL: Config.step_02_multiTaskURL)
        scrollToAndTap(app.buttons[Config.step_02_podcastName])
        openEpisode(Config.step_02_episodeKey)

        snapshot("02_Episode_Details_MultiTask")

        // 02 - Teardown
        stopMultiTask()
        app.buttons["Close"].firstMatch.waitForThenTap()
        app.buttons["Close"].firstMatch.waitForThenTap()
        XCUIDevice.shared.orientation = .portrait

        // 03 - Player with Multi-Task (Landscape)
        XCUIDevice.shared.orientation = .landscapeLeft

        scrollToAndTap(app.buttons[Config.step_03_podcastName])
        openEpisode(Config.step_03_episodeKey)

        startMultiTask(withURL: Config.step_03_multiTaskURL)

        hittablePlayButton.waitForThenTap()

        if !app.buttons["Close player"].exists {
            app.buttons["Player"].waitForThenTap()
        }

        snapshot("03_Player_With_MultiTask")

        // 03 - Teardown
        hittablePlayButton.waitForThenTap()
        app.buttons["Close player"].waitForThenTap()
        app.buttons["Close"].waitForThenTap()
        stopMultiTask()
        XCUIDevice.shared.orientation = .portrait
    }

    func test_generateScreenshots_darkMode() throws {
        // 04 - Dark Mode Podcast Page
        navigateToApperance()
        enableSystemThemeMatching()
        backButton.waitForThenTap()
        backButton.waitForThenTap()
        selectTab(.podcasts)

        scrollToAndTap(app.buttons[Config.step_04_podcastName])
        snapshot("04_Podcast_Page_Default_Dark_Theme")

        // 04 - Teardown
        app.buttons["Close"].waitForThenTap()
    }
}

extension iPad_GenerateScreenshots {
    private func startMultiTask(withURL url: String) {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)).tap()

        safari.launch()
        XCTAssert(safari.wait(for: .runningForeground, timeout: 5))

        safariLoad(url: url)
    }

    private func stopMultiTask() {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.02)).tap()
    }
}
