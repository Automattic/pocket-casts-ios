import SwiftUI
import PocketCastsUtils

struct ListeningHeatmapView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: ListeningHeatmapViewModel

    @ScaledMetric private var cellSize: CGFloat = 12
    @ScaledMetric private var cellSpacing: CGFloat = 3
    @ScaledMetric(relativeTo: .caption2) private var dayLabelWidth: CGFloat = 28
    @ScaledMetric(relativeTo: .caption2) private var monthLabelHeight: CGFloat = 14

    private let gridLeadingPadding: CGFloat = 4
    private let gridTrailingPadding: CGFloat = 8
    private let monthLabelBottomPadding: CGFloat = 4

    private var calendar: Calendar { viewModel.calendar }
    private var columnWidth: CGFloat { cellSize + cellSpacing }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heatmapGrid

            legendRow
                .padding(.horizontal, gridTrailingPadding)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heatmapGrid: some View {
        GeometryReader { geometry in
            let visibleWeeks = computeVisibleWeeks(availableWidth: geometry.size.width)
            VStack(alignment: .leading, spacing: 0) {
                monthLabels(weeks: visibleWeeks)
                    .padding(.leading, dayLabelWidth + cellSpacing)
                    .padding(.bottom, monthLabelBottomPadding)

                HStack(alignment: .top, spacing: cellSpacing) {
                    dayLabels

                    ForEach(visibleWeeks.indices, id: \.self) { weekIndex in
                        VStack(spacing: cellSpacing) {
                            ForEach(visibleWeeks[weekIndex]) { day in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorForIntensity(day.intensity))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .padding(.leading, gridLeadingPadding)
            .padding(.trailing, gridTrailingPadding)
        }
        .frame(height: gridHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let count = viewModel.weeks.reduce(0) { partial, week in
            partial + week.reduce(0) { $0 + ($1.seconds > 0 ? 1 : 0) }
        }
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
        return L10n.statsListeningActivityAccessibilityLabel(formatted)
    }

    private var gridHeight: CGFloat {
        7 * cellSize + 6 * cellSpacing + monthLabelHeight + monthLabelBottomPadding
    }

    private func computeVisibleWeeks(availableWidth: CGFloat) -> [[HeatmapDay]] {
        guard availableWidth > 0 else { return [] }
        let usable = availableWidth - dayLabelWidth - cellSpacing - gridLeadingPadding - gridTrailingPadding
        let maxVisible = max(0, Int((usable + cellSpacing) / columnWidth))
        guard maxVisible > 0 else { return [] }
        return Array(viewModel.weeks.suffix(maxVisible))
    }

    private var dayLabels: some View {
        let symbols = calendar.shortWeekdaySymbols
        return VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { rowIndex in
                if rowIndex % 2 == 0 {
                    let symbolIndex = (calendar.firstWeekday - 1 + rowIndex) % 7
                    Text(symbols[symbolIndex])
                        .font(size: 10, style: .caption2, weight: .medium)
                        .foregroundColor(theme.primaryText02)
                        .frame(width: dayLabelWidth, height: cellSize, alignment: .trailing)
                } else {
                    Color.clear
                        .frame(width: dayLabelWidth, height: cellSize)
                }
            }
        }
    }

    private func monthLabels(weeks: [[HeatmapDay]]) -> some View {
        let monthPositions = computeMonthPositions(weeks: weeks)
        return ZStack(alignment: .leading) {
            Color.clear.frame(height: monthLabelHeight)

            ForEach(monthPositions, id: \.weekIndex) { position in
                Text(position.label)
                    .font(size: 10, style: .caption2, weight: .medium)
                    .foregroundColor(theme.primaryText02)
                    .offset(x: CGFloat(position.weekIndex) * columnWidth)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 4) {
            Spacer()
            Text(L10n.statsListeningActivityLegendLess)
                .font(size: 10, style: .caption2, weight: .regular)
                .foregroundColor(theme.primaryText02)
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForIntensity(level))
                    .frame(width: cellSize, height: cellSize)
            }
            Text(L10n.statsListeningActivityLegendMore)
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

    private func computeMonthPositions(weeks: [[HeatmapDay]]) -> [MonthPosition] {
        var positions: [MonthPosition] = []
        let shortMonths = calendar.shortMonthSymbols

        for (weekIndex, week) in weeks.enumerated() {
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

// MARK: - Previews
#Preview {
    VStack {
        ListeningHeatmapView(viewModel: .init())
        Spacer()
    }
    .setupDefaultEnvironment()
    .dynamicTypeSize(DynamicTypeSize.medium...DynamicTypeSize.accessibility2)
}
