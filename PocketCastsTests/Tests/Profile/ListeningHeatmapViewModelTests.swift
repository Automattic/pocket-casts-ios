import XCTest
import Combine

@testable import PocketCastsDataModel
@testable import podcasts

final class ListeningHeatmapViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Week alignment (English locale)

    func testBuildWeeks_enUS_firstDayIsSunday() throws {
        let viewModel = makeViewModel(today: date(2026, 4, 20))

        let weeks = viewModel.buildWeeks(from: [:])

        let firstDay = try XCTUnwrap(weeks.first?.first).date
        XCTAssertEqual(enUSCalendar.component(.weekday, from: firstDay), 1, "First column day should be Sunday in en_US")
    }

    func testBuildWeeks_enUS_lastDayIsToday() throws {
        let today = date(2026, 4, 20)
        let viewModel = makeViewModel(today: today)

        let weeks = viewModel.buildWeeks(from: [:])

        let lastDay = try XCTUnwrap(weeks.last?.last).date
        XCTAssertEqual(lastDay, enUSCalendar.startOfDay(for: today))
    }

    func testBuildWeeks_enUS_gridSpansOneFullYear() {
        // today = Monday 2026-04-20. Start of grid: Sunday 2025-04-20 (the week containing
        // today - 364 days = Monday 2025-04-21). That's 366 days = 53 columns.
        let viewModel = makeViewModel(today: date(2026, 4, 20))

        let weeks = viewModel.buildWeeks(from: [:])

        XCTAssertEqual(weeks.count, 53)
        XCTAssertEqual(weeks.dropLast().allSatisfy { $0.count == 7 }, true)
        XCTAssertEqual(weeks.last?.count, 2) // Sun + Mon
    }

    // MARK: - Data mapping

    func testBuildWeeks_emptyData_allIntensityZero() {
        let viewModel = makeViewModel(today: date(2026, 4, 20))

        let weeks = viewModel.buildWeeks(from: [:])

        XCTAssertTrue(weeks.flatMap { $0 }.allSatisfy { $0.intensity == 0 })
    }

    func testBuildWeeks_intensityAssignsLevels1Through4() {
        let today = date(2026, 4, 20)
        let viewModel = makeViewModel(today: today)

        // 8 sorted values: [10, 20, 40, 50, 60, 70, 80, 100].
        // thresholds: sorted[2]=40, sorted[4]=60, sorted[6]=80.
        // Expected: 10→1, 50→2, 70→3, 100→4.
        let data: [String: Double] = [
            "2026-04-01": 10,
            "2026-04-02": 20,
            "2026-04-03": 40,
            "2026-04-04": 50,
            "2026-04-05": 60,
            "2026-04-06": 70,
            "2026-04-07": 80,
            "2026-04-08": 100
        ]

        let weeks = viewModel.buildWeeks(from: data)
        let bySeconds = Dictionary(uniqueKeysWithValues: weeks
            .flatMap { $0 }
            .filter { $0.seconds > 0 }
            .map { ($0.seconds, $0.intensity) })

        XCTAssertEqual(bySeconds[10], 1)
        XCTAssertEqual(bySeconds[50], 2)
        XCTAssertEqual(bySeconds[70], 3)
        XCTAssertEqual(bySeconds[100], 4)
    }

    // MARK: - load() end-to-end with injected DataManager

    func testLoad_emptyData_setsHasDataFalseAndAllIntensityZero() {
        let dataManagerMock = DataManagerMock()
        dataManagerMock.dailyListeningTimeToReturn = [:]
        let viewModel = makeViewModel(dataManager: dataManagerMock, today: date(2026, 4, 20))

        waitForLoad(viewModel)

        XCTAssertFalse(viewModel.hasData)
        XCTAssertEqual(viewModel.weeks.count, 53)
        XCTAssertTrue(viewModel.weeks.flatMap { $0 }.allSatisfy { $0.intensity == 0 })
    }

    func testLoad_withData_computesIntensitiesFromQuartiles() {
        let dataManagerMock = DataManagerMock()
        // 4 sorted values: [100, 300, 600, 1200].
        // thresholds: sorted[1]=300, sorted[2]=600, sorted[3]=1200.
        // Expected: 100→1, 300→1, 600→2, 1200→3.
        dataManagerMock.dailyListeningTimeToReturn = [
            "2026-04-10": 100,
            "2026-04-11": 300,
            "2026-04-12": 600,
            "2026-04-13": 1200
        ]
        let viewModel = makeViewModel(dataManager: dataManagerMock, today: date(2026, 4, 20))

        waitForLoad(viewModel)

        XCTAssertTrue(viewModel.hasData)
        let bySeconds = Dictionary(uniqueKeysWithValues: viewModel.weeks
            .flatMap { $0 }
            .filter { $0.seconds > 0 }
            .map { ($0.seconds, $0.intensity) })
        XCTAssertEqual(bySeconds[100], 1)
        XCTAssertEqual(bySeconds[300], 1)
        XCTAssertEqual(bySeconds[600], 2)
        XCTAssertEqual(bySeconds[1200], 3)
    }

    // MARK: - Helpers

    private lazy var enUSCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = 1 // Sunday
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func makeViewModel(
        dataManager: DataManager = DataManagerMock(),
        today: Date
    ) -> ListeningHeatmapViewModel {
        ListeningHeatmapViewModel(dataManager: dataManager, calendar: enUSCalendar, now: today)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        enUSCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func formattedKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = enUSCalendar.timeZone
        return formatter.string(from: date)
    }

    private func waitForLoad(_ viewModel: ListeningHeatmapViewModel) {
        let expectation = XCTestExpectation(description: "weeks published")
        viewModel.$weeks
            .dropFirst()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        viewModel.load()
        wait(for: [expectation], timeout: 2.0)
    }
}
