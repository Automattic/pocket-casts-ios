import XCTest

@testable import podcasts

@MainActor
final class EffectsButtonTests: XCTestCase {
    func testLabelIsPlaybackEffectsWhenEffectsAreOff() {
        let button = EffectsButton(frame: .zero)

        XCTAssertEqual(button.accessibilityLabel, L10n.playerActionTitleEffects)
        XCTAssertEqual(button.accessibilityValue, L10n.off)
    }

    func testValueFollowsEffectsState() {
        let button = EffectsButton(frame: .zero)

        button.effectsOn = true
        XCTAssertEqual(button.accessibilityLabel, L10n.playerActionTitleEffects)
        XCTAssertEqual(button.accessibilityValue, L10n.on)

        button.effectsOn = false
        XCTAssertEqual(button.accessibilityLabel, L10n.playerActionTitleEffects)
        XCTAssertEqual(button.accessibilityValue, L10n.off)
    }
}
