import SwiftUI

/// A label used in the end of year stories that provides consistent styling
/// This preprocesses the text to improve the typography
struct StoryLabel: View {
    private let text: String
    private let highlights: [String]?
    private let type: StoryLabelType

    init(_ text: String, highlighting: [String]? = nil, for type: StoryLabelType) {
        self.text = Self.processText(text)
        self.highlights = highlighting
        self.type = type
    }

    var body: some View {
        if #available(iOS 15, *) {
            if let attributedString {
                applyDefaults(Text(attributedString), forHighlights: true)
            } else {
                applyDefaults(Text(text))
            }
        } else {
            applyDefaults(Text(text))
        }
    }

    private func applyDefaults(_ content: some View, forHighlights: Bool = false) -> some View {
        return content
            .foregroundColor(.white)
            .lineSpacing(2.5)
            .multilineTextAlignment(.center)
            .font(forHighlights ? nil : font)
            .padding([.leading, .trailing], horizontalPadding)
    }

    @available(iOS 15, *)
    private var attributedString: AttributedString? {
        guard let highlights else { return nil }

        var string = AttributedString(text)
        // Since we're highlighting using bold, change the normal text to regular weight
        string.font = font.weight(.regular)
        let highlightFont = font.weight(.bold)

        for text in highlights {
            if let range = string.range(of: text) {
                string[range].font = highlightFont
            }
            // The highlight text may have been processed so run it through to see if that hits
            else if let range = string.range(of: Self.processText(text)) {
                string[range].font = highlightFont
            }
        }

        return string
    }

    private static func processText(_ text: String) -> String {
        let returnText = text
        // Typographic apostrophes
            .replacingOccurrences(of: "'", with: "ʼ")
        // Prevent Pocket Casts from being separated
            .replacingOccurrences(of: "Pocket Casts", with: "Pocket\u{00a0}Casts")

        let components = returnText.components(separatedBy: " ")

        guard components.count > 1 else {
            return returnText
        }

        let count = components.count - 1
        var builder: [String] = []

        for (index, word) in components.enumerated() {
            let isLast = index == count

            builder.append(isLast ? "\u{00a0}" : " ")
            builder.append(word)
        }

        return builder.joined()
    }

    enum StoryLabelType {
        case title
        case title2
        case subtitle
        case pillarTitle
        case pillarSubtitle
    }

    private var font: Font {
        switch type {
        case .title:
            return .system(size: 22, weight: .bold)
        case .title2:
            return .system(size: 18, weight: .bold)
        case .subtitle:
            return .system(size: 15, weight: .regular)
        case .pillarTitle:
            return .system(size: 14, weight: .heavy)
        case .pillarSubtitle:
            return .system(size: 12, weight: .bold)
        }
    }

    private var horizontalPadding: CGFloat {
        switch type {
        case .pillarTitle, .pillarSubtitle:
            return 0
        default:
            return 35
        }
    }
}

// MARK: - Story time formatter
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
        calculateStoryTimeDescription(unitSeparator: "\u{00a0}", componentSeparator: "\n")
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
}
