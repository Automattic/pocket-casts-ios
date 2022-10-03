import XCTest

private extension Config {
    static let step_02_podcastName = "Serial"
    static let step_03_podcastName = "Connected"
    static let step_03_episodeKey = "377"
    static let step_05_podcastName = "All In The Mind"
    static let step_06_podcastName = "Distributed, with Matt Mullenweg"
    static let step_06_episodeKey = "Distributed by Default"

    static let watch_setup_podcastName = "The Vergecast"
    static let watch_setup_episodeKey = "481"
    static let watch_setup_podcastNameToDownload = "Download This Show"
    static let watch_setup_episodeKeyToDownload = "Wordle"
}

class iPhone_GenerateScreenshots: GenerateScreenshots {
    func test_watchSetup() throws {
        XCTAssert(app.wait(for: .runningForeground, timeout: 5))
        selectTab(.podcasts)

        scrollToAndTap(app.buttons[Config.watch_setup_podcastName])
        openEpisode(Config.watch_setup_episodeKey)
        hittablePlayButton.waitForThenTap()

        // Pause episode
        hittablePlayButton.waitForThenTap()

        // Skip Forward a bit to show progress
        for _ in 0 ... 30 {
            app.buttons["Skip Forward"].waitForThenTap()
        }

        app.buttons["Close"].waitForThenTap()

        scrollToAndTap(app.buttons[Config.watch_setup_podcastNameToDownload])
        openEpisode(Config.watch_setup_episodeKeyToDownload)

        // Download an episode
        if !app.buttons["Remove Download"].exists {
            app.buttons["Download"].waitForThenTap()
        }

        // Wait for the episode to download
        let _ = app.buttons["Remove Download"].waitForExistence(timeout: 120)

        // Background the app to make sure CoreData saves
        safari.launch()
    }

    func test_generateScreenshots() throws {
        // 01 - Podcast List (Default Light Theme)
        selectTab(.podcasts)
        snapshot("01_Podcast_List")

        // 02 - Podcast Page (Default Light Theme)
        scrollToAndTap(app.buttons[Config.step_02_podcastName])
        snapshot("02_Podcast_Page_Default_Light_Theme")

        // 02 Teardown
        app.buttons["Close"].waitForThenTap()

        // 03 - Player With Chapters
        scrollToAndTap(app.buttons[Config.step_03_podcastName])
        openEpisode(Config.step_03_episodeKey)

        hittablePlayButton.waitForThenTap()

        if !app.buttons["Close player"].exists {
            app.buttons["Player"].waitForThenTap()
        }

        snapshot("03_Player_With_Chapters")

        // 03 Teardown
        hittablePlayButton.waitForThenTap()
        app.buttons["Close player"].waitForThenTap()
        app.buttons["Close"].waitForThenTap()

        // 04 - Theme Selection
        navigateToApperance()
        enableSystemThemeMatching()
        snapshot("04_Theme_Options")

        // 04 Teardown
        backButton.waitForThenTap()
        backButton.waitForThenTap()
        selectTab(.podcasts)

        // 06 - Episode Details (Default Light Theme)
        scrollToAndTap(app.buttons[Config.step_06_podcastName])
        openEpisode(Config.step_06_episodeKey)
        snapshot("06_Episode_Details")

        // 06 Teardown
        app.buttons["Close"].firstMatch.waitForThenTap()
        app.buttons["Close"].firstMatch.waitForThenTap()

        // 07 - Filters (Default Light Theme)
        selectTab(.filters)
        app.cells.firstMatch.waitForThenTap()

        app.buttons["expandFilter"].waitForThenTap()
        snapshot("07_Filters")

        // 07 Teardown
        backButton.waitForThenTap()
        selectTab(.podcasts)
    }

    func test_generateScreenshots_darkMode() throws {
        // 05 - Podcast Page (Default Dark Theme)
        navigateToApperance()
        enableSystemThemeMatching()
        backButton.waitForThenTap()
        backButton.waitForThenTap()
        selectTab(.podcasts)

        scrollToAndTap(app.buttons[Config.step_05_podcastName])
        snapshot("05_Podcast_Page_Default_Dark_Theme")

        // 05 Teardown
        app.buttons["Close"].waitForThenTap()
    }
}
