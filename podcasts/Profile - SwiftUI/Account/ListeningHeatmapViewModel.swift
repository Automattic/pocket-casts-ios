import Foundation
import PocketCastsDataModel

struct HeatmapDay: Identifiable {
    var id: Date { date }
    let date: Date
    let seconds: Double
    let intensity: Int // 0-4
}

class ListeningHeatmapViewModel: ObservableObject {
    @Published var weeks: [[HeatmapDay]] = []
    @Published var hasData = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let rawData = DataManager.sharedManager.dailyListeningTime(forLast: 365)
            let weeks = self.buildWeeks(from: rawData)
            let hasData = rawData.values.contains(where: { $0 > 0 })

            DispatchQueue.main.async {
                self.weeks = weeks
                self.hasData = hasData
            }
        }
    }

    private func buildWeeks(from data: [String: Double]) -> [[HeatmapDay]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find the Sunday that starts the week containing the day 364 days ago
        let startDay = calendar.date(byAdding: .day, value: -364, to: today)!
        let weekday = calendar.component(.weekday, from: startDay)
        // weekday: 1 = Sunday. We want to align to Sunday.
        let startSunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: startDay)!

        // Build all days from startSunday to today
        var allDays: [HeatmapDay] = []
        var current = startSunday
        while current <= today {
            let key = Self.dateFormatter.string(from: current)
            let seconds = data[key] ?? 0
            allDays.append(HeatmapDay(id: current, date: current, seconds: seconds, intensity: 0))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        // Compute intensity quartiles from non-zero days
        let nonZeroValues = allDays.compactMap { $0.seconds > 0 ? $0.seconds : nil }.sorted()
        let thresholds = quartileThresholds(from: nonZeroValues)

        for i in allDays.indices {
            allDays[i].intensity = intensityLevel(for: allDays[i].seconds, thresholds: thresholds)
        }

        // Group into weeks (columns of 7 days, Sunday-Saturday)
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
