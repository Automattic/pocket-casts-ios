import XCTest

extension XCUIElement {
    func expectExistence(timeout: TimeInterval = 10) {
        XCTAssert(waitForExistence(timeout: timeout), "Element Not Found: \(identifier)")
    }

    func waitForThenTap(timeout: TimeInterval = 10) {
        expectExistence(timeout: timeout)
        var count = 0
        while !isHittable, count < Int(timeout) {
            sleep(1)
            count += 1
        }

        tap()
    }
}

extension XCUIElementQuery {
    func scrollPercent() -> Int {
        let verticalScrollBarPercent = otherElements.allElementsBoundByIndex.first!.value as! String
        return Int(verticalScrollBarPercent.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines))!
    }
}
