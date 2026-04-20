import SwiftUI
import PocketCastsUtils

struct ListeningHeatmapView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: ListeningHeatmapViewModel

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    var body: some View {
        if viewModel.hasData {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.listeningActivity)
                    .font(size: 14, style: .subheadline, weight: .semibold)
                    .foregroundColor(theme.primaryText01)
                    .padding(.horizontal, 16)

                heatmapGrid

                legendRow
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Heatmap Grid

    private var heatmapGrid: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    monthLabels
                        .padding(.leading, dayLabelWidth + cellSpacing)
                        .padding(.bottom, 4)

                    HStack(alignment: .top, spacing: cellSpacing) {
                        dayLabels

                        ForEach(Array(viewModel.weeks.enumerated()), id: \.offset) { weekIndex, week in
                            VStack(spacing: cellSpacing) {
                                ForEach(week) { day in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colorForIntensity(day.intensity))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                            .id(weekIndex)
                        }
                    }
                }
                .padding(.leading, 4)
                .padding(.trailing, 16)
            }
            .onAppear {
                if !viewModel.weeks.isEmpty {
                    proxy.scrollTo(viewModel.weeks.count - 1, anchor: .trailing)
                }
            }
        }
    }

    // MARK: - Day Labels

    private let dayLabelWidth: CGFloat = 24

    private var dayLabels: some View {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        // Label every other row starting from firstWeekday (rows 0, 2, 4, 6).
        let labeledRows: Set<Int> = [0, 2, 4, 6]
        return VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { rowIndex in
                if labeledRows.contains(rowIndex) {
                    let symbolIndex = (calendar.firstWeekday - 1 + rowIndex) % 7
                    Text(symbols[symbolIndex])
                        .font(size: 10, style: .caption2, weight: .regular)
                        .foregroundColor(theme.primaryText02)
                        .frame(width: dayLabelWidth, height: cellSize, alignment: .trailing)
                } else {
                    Color.clear
                        .frame(width: dayLabelWidth, height: cellSize)
                }
            }
        }
    }

    // MARK: - Month Labels

    private var monthLabels: some View {
        let calendar = Calendar.current
        let monthPositions = computeMonthPositions(calendar: calendar)
        let columnWidth = cellSize + cellSpacing

        return ZStack(alignment: .leading) {
            Color.clear.frame(height: 14)

            ForEach(monthPositions, id: \.weekIndex) { position in
                Text(position.label)
                    .font(size: 10, style: .caption2, weight: .regular)
                    .foregroundColor(theme.primaryText02)
                    .offset(x: CGFloat(position.weekIndex) * columnWidth)
            }
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 4) {
            Spacer()
            Text(L10n.less)
                .font(size: 10, style: .caption2, weight: .regular)
                .foregroundColor(theme.primaryText02)
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForIntensity(level))
                    .frame(width: cellSize, height: cellSize)
            }
            Text(L10n.more)
                .font(size: 10, style: .caption2, weight: .regular)
                .foregroundColor(theme.primaryText02)
        }
    }

    // MARK: - Helpers

    private func colorForIntensity(_ level: Int) -> Color {
        switch level {
        case 0: return theme.primaryUi05.opacity(0.3)
        case 1: return theme.primaryInteractive01.opacity(0.3)
        case 2: return theme.primaryInteractive01.opacity(0.5)
        case 3: return theme.primaryInteractive01.opacity(0.75)
        case 4: return theme.primaryInteractive01
        default: return theme.primaryUi05.opacity(0.3)
        }
    }

    private struct MonthPosition {
        let weekIndex: Int
        let label: String
    }

    private func computeMonthPositions(calendar: Calendar) -> [MonthPosition] {
        var positions: [MonthPosition] = []
        let shortMonths = calendar.shortMonthSymbols

        for (weekIndex, week) in viewModel.weeks.enumerated() {
            guard let firstDay = week.first else { continue }
            let day = calendar.component(.day, from: firstDay.date)
            if day <= 7 {
                let month = calendar.component(.month, from: firstDay.date)
                positions.append(MonthPosition(weekIndex: weekIndex, label: shortMonths[month - 1]))
            }
        }

        return positions
    }
}
