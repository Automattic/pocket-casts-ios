import SwiftUI

/// A label used in the end of year stories that provides consistent styling
struct StoryLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
        // Prevent widows from appearing due to the extra space of the ellipsis characters
        // Replace them with the single character space equivalent
            .replacingOccurrences(of: "...", with: "…")

        // Don't allow the word Pocket Casts to be broken up by inserting a non-breaking space
            .replacingOccurrences(of: "Pocket Casts", with: "Pocket\u{00a0}Casts")
    }

    var body: some View {
        Text(text)
            .lineSpacing(2.5)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
    }
}


extension Double {
    var storyTimeDescription: String {
        // Prevent the time from being split across paragraphs by replacing the spaces with non breaking ones
        calculateStoryTimeDescription(unitSeparator: "\u{00a0}", componentSeparator: "\u{00a0}")
    }

    /// Return normal text when displaying the time for sharing
    var storyTimeDescriptionForSharing: String {
        calculateStoryTimeDescription()
    }

    /// For displaying units above the category pillars, allow the time components to be broken up across
    /// multiple lines, but don't let the unit (10 minutes) itself to be broken up
    var storyTimeDescriptionForPillars: String {
        calculateStoryTimeDescription(unitSeparator: "\u{00a0}", componentSeparator: " ")
    }
}

// MARK: - Custom Time Formatter that allows customizing of the spacing between units
private extension Double {
    func calculateStoryTimeDescription(unitSeparator: String = " ", componentSeparator: String = " ") -> String {
        var output: [String?] = []

        // If we're less than a minute, then just return seconds
        let days = Int(safeDouble: self / 86400)
        let hours = Int(safeDouble: self / 3600) - (days * 24)
        let mins = Int(safeDouble: self / 60) - (hours * 60) - (days * 24 * 60)
        let secs = Int(safeDouble: self.truncatingRemainder(dividingBy: 60))

        // If we're showing hours, then don't include the seconds, only days | hours | mins
        if days > 0, hours > 0 {
            output.append(format(days, unit: .day))
            output.append(format(hours, unit: .hour))
        } else {
            output.append(format(days, unit: .day))
            output.append(format(hours, unit: .hour))

            let secondsForDisplay = hours < 1 ? secs : 0
            output.append(format(mins, unit: .minute))
            output.append(format(secondsForDisplay, unit: .second))
        }

        // Check if we have nothing to display, and default to showing seconds
        if output.lazy.compactMap({ $0 }).isEmpty {
            output.append(format(secs, unit: .second, zeroCheck: false))
        }

        return output
            // Strip out nil values and convert unit separators
            .compactMap {
                $0?.replacingOccurrences(of: " ", with: unitSeparator)
            }
            // Return the final joined string with the custom separator between components
            .joined(separator: componentSeparator)
    }

    private func format(_ value: Int, unit: Calendar.Component, zeroCheck: Bool = true) -> String? {
        if zeroCheck && value == 0 {
            return nil
        }

        let components: DateComponents
        switch unit {
        case .day:
            components = DateComponents(calendar: Calendar.current, day: value)
        case .hour:
            components = DateComponents(calendar: Calendar.current, hour: value)
        case .minute:
            components = DateComponents(calendar: Calendar.current, minute: value)
        case .second:
            components = DateComponents(calendar: Calendar.current, second: value)
        default:
            components = DateComponents(calendar: Calendar.current, second: value)
        }

        return DateComponentsFormatter.localizedString(from: components, unitsStyle: .full)?.replacingOccurrences(of: ",", with: "")
    }

    private enum Constants {
        static let OneMinute = 60
        static let OneHour = 3_600
        static let OneDay = 86_400
    }
}
