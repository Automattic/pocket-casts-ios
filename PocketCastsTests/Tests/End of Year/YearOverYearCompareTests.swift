import Testing
@testable import podcasts

struct YearOverYearCompareCalculator {

    @Test func testUptrend() async throws {

        let listened2023: Double = 1000
        let listened2024: Double = 5000

        let comparison = YearOverYearCompare2024Story.Comparison(in2023: listened2023, in2024: listened2024)
        let isUp: Bool

        let difference: Double
        switch comparison {
        case .up(let diff):
            isUp = true
            difference = diff
        default:
            isUp = false
            difference = 0
        }

        #expect(isUp, "Comparison should be Up")
        let differenceRatio = listened2024/listened2023
        #expect(difference == differenceRatio, "Difference should be in percentage. Instead it's \(comparison)")
    }

    @Test func testDowntrend() async throws {

        let listened2023: Double = 5000
        let listened2024: Double = 1000

        let comparison = YearOverYearCompare2024Story.Comparison(in2023: listened2023, in2024: listened2024)
        let isDown: Bool

        let difference: Double
        switch comparison {
        case .down(let diff):
            isDown = true
            difference = diff
        default:
            isDown = false
            difference = 0
        }

        #expect(isDown, "Comparison should be Down")
        let differenceRatio = listened2024/listened2023
        #expect(difference == differenceRatio, "Difference should be in percentage. Instead it's \(comparison)")
    }

    @Test func testSame() async throws {

        let listened2023: Double = 1100
        let listened2024: Double = 1000

        let comparison = YearOverYearCompare2024Story.Comparison(in2023: listened2023, in2024: listened2024)
        let isSame: Bool

        switch comparison {
        case .same:
            isSame = true
        default:
            isSame = false
        }

        #expect(isSame, "Comparison should be Same. Instead it's \(comparison)")
    }

    @Test func testMissing2023() async throws {

        let listened2023: Double = 0
        let listened2024: Double = 1000

        let comparison = YearOverYearCompare2024Story.Comparison(in2023: listened2023, in2024: listened2024)
        let isUp: Bool

        switch comparison {
        case .up:
            isUp = true
        default:
            isUp = false
        }

        #expect(isUp, "Comparison should be Up. Instead it's \(comparison)")
    }

    @Test func testUptrend2025() async throws {

        let listened2024: Double = 1000
        let listened2025: Double = 1200

        let comparison = YearOverYearCompare2025Story.Comparison(in2024: listened2024, in2025: listened2025)
        let isUp: Bool

        let difference: Double
        switch comparison {
            case .up(let diff):
                isUp = true
                difference = diff
            default:
                isUp = false
                difference = 0
        }

        #expect(isUp, "Comparison should be Up")
        #expect(abs(difference - 0.2) < 0.001, "Difference should be in percentage. Instead it's \(comparison)")
    }

    @Test func testDowntrend2025() async throws {

        let listened2024: Double = 1000
        let listened2025: Double = 800

        let comparison = YearOverYearCompare2025Story.Comparison(in2024: listened2024, in2025: listened2025)
        let isDown: Bool

        let difference: Double
        switch comparison {
            case .down(let diff):
                isDown = true
                difference = diff
            default:
                isDown = false
                difference = 0
        }

        #expect(isDown, "Comparison should be Down")
        #expect(abs(difference - 0.2) < 0.001, "Difference should be in percentage. Instead it's \(comparison)")
    }
}
