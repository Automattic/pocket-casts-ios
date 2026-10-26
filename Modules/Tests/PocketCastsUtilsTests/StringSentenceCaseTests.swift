@testable import PocketCastsUtils
import XCTest

class StringSentenceCaseTests: XCTestCase {
    func testEnglishLowercasesAllButTheFirstWord() {
        XCTAssertEqual("Episode Status".sentenceCased(locale: Locale(identifier: "en_US")), "Episode status")
    }

    func testGermanKeepsNounCapitalization() {
        let locale = Locale(identifier: "de_DE")
        XCTAssertEqual("Status der Folge".sentenceCased(locale: locale), "Status der Folge")
        XCTAssertEqual("Mit Stern markiert".sentenceCased(locale: locale), "Mit Stern markiert")
    }
}
