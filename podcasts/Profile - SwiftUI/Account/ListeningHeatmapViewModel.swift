import Foundation
import PocketCastsDataModel
import PocketCastsUtils

struct HeatmapDay: Identifiable {
    var id: Date { date }
    let date: Date
    let seconds: Double
    let intensity: Int // 0-4
}

final class ListeningHeatmapViewModel: ObservableObject {
    @Published private(set) var weeks: [[HeatmapDay]] = []

    private let dataManager: DataManager
    private let calendar: Calendar
    private let now: Date
    private let dateFormatter: DateFormatter

    private let daysOfHistory = 365

    init(
        dataManager: DataManager = DataManager.sharedManager,
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        self.dataManager = dataManager
        self.calendar = calendar
        self.now = now

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        self.dateFormatter = formatter

        self.weeks = buildWeeks(from: [:])
    }

    func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let rawData = self.dataManager.dailyListeningTime(forLast: self.daysOfHistory)
            let weeks = self.buildWeeks(from: rawData)

            DispatchQueue.main.async {
                self.weeks = weeks
            }
        }
    }

    func buildWeeks(from data: [String: Double]) -> [[HeatmapDay]] {
        let today = calendar.startOfDay(for: now)

        // Align to the start of the week (locale-aware) containing the oldest day in the window.
        guard let startDay = calendar.date(byAdding: .day, value: -(daysOfHistory - 1), to: today),
              let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startDay)?.start else {
            assertionFailure("ListeningHeatmapViewModel: failed to compute heatmap date range")
            FileLog.shared.addMessage("ListeningHeatmapViewModel: failed to compute heatmap date range")
            return []
        }

        var rawDays: [(date: Date, seconds: Double)] = []
        var current = startOfWeek
        while current <= today {
            let key = dateFormatter.string(from: current)
            rawDays.append((current, data[key] ?? 0))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                assertionFailure("ListeningHeatmapViewModel: failed to advance date by one day")
                FileLog.shared.addMessage("ListeningHeatmapViewModel: failed to advance date by one day")
                return []
            }
            current = next
        }

        // Compute intensity quartiles from non-zero days
        let nonZeroValues = rawDays.compactMap { $0.seconds > 0 ? $0.seconds : nil }.sorted()
        let thresholds = quartileThresholds(from: nonZeroValues)

        let allDays = rawDays.map { day in
            HeatmapDay(
                date: day.date,
                seconds: day.seconds,
                intensity: intensityLevel(for: day.seconds, thresholds: thresholds)
            )
        }

        // Group into weeks (columns of 7 days, aligned to calendar.firstWeekday).
        var weeks: [[HeatmapDay]] = []
        var week: [HeatmapDay] = []
        for day in allDays {
            week.append(day)
            if week.count == 7 {
                weeks.append(week)
                week = []
            }
        }
        if !week.isEmpty {
            weeks.append(week)
        }

        return weeks
    }

    private func quartileThresholds(from sorted: [Double]) -> [Double] {
        guard !sorted.isEmpty else { return [] }
        let count = sorted.count
        return [
            sorted[count / 4],
            sorted[count / 2],
            sorted[count * 3 / 4]
        ]
    }

    private func intensityLevel(for seconds: Double, thresholds: [Double]) -> Int {
        guard seconds > 0 else { return 0 }
        guard thresholds.count == 3 else { return 1 }
        if seconds <= thresholds[0] { return 1 }
        if seconds <= thresholds[1] { return 2 }
        if seconds <= thresholds[2] { return 3 }
        return 4
    }
}
