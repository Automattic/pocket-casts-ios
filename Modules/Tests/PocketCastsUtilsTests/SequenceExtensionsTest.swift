import Foundation
import PocketCastsUtils
import XCTest

final class SequenceExtensionsTest: XCTestCase {
    private let count = 50000

    func testMapFirstReturnsCorrectValue() {
        let nonNilValue = Int.random(in: 0..<count)

        // Fill the array with only a single non-nil value
        var data: [MapFirstTestStruct] = []
        for i in 0..<count {
            if i == nonNilValue {
                data.append(.init(value: "🍃 Yahaha! You found me!"))
            } else {
                data.append(.init(value: nil))
            }
        }

        XCTAssertEqual(data.mapFirst({ $0.value }), data[nonNilValue].value)
    }

    func testMapFirstTransformIsCalledOnlyUntilNonNilValueIsFound() {
        let data = [
            MapFirstTestStruct(value: nil),
            MapFirstTestStruct(value: "One"),
            MapFirstTestStruct(value: "2"),
            MapFirstTestStruct(value: "3")
        ]

        var count = 0
        let _ = data.mapFirst {
            count += 1
            return $0.value
        }

        XCTAssertEqual(count, 2)
    }

    func testMapFirstReturnsFirstNonNilValue() {
        let nonNilValue = Int.random(in: 0..<count)
        // Fill the array with multiple non-nil values to ensure only the first is returned
        var data: [MapFirstTestStruct] = []
        for i in 0..<count {
            if i >= nonNilValue {
                data.append(.init(value: "🍃 Yahaha! You found me! \(i)"))
                continue
            }

            data.append(.init(value: nil))
        }

        XCTAssertEqual(data.mapFirst({ $0.value }), data[nonNilValue].value)
    }
}

private struct MapFirstTestStruct {
    let value: String?
}
