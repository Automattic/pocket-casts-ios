import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

/// A label used in the end of year stories that provides consistent styling
/// This preprocesses the text to improve the typography
struct StoryLabel: View {
    private let text: String
    private let highlights: [String]?
    private let type: StoryLabelType
    private let geometry: GeometryProxy
    private let color: Color

    init(_ text: String, highlighting: [String]? = nil, for type: StoryLabelType, color: Color = .white, geometry: GeometryProxy) {
        self.text = Self.processText(text)
        self.highlights = highlighting
        self.type = type
        self.geometry = geometry
        self.color = color
    }

    var body: some View {
        if let attributedString {
            applyDefaults(Text(attributedString), forHighlights: true)
        } else {
            applyDefaults(Text(text))
        }
    }

    private func applyDefaults(_ content: some View, forHighlights: Bool = false) -> some View {
        return content
            .foregroundColor(color)
            .lineSpacing(0)
            .multilineTextAlignment(.center)
            .font(forHighlights ? nil : font)
            .padding([.leading, .trailing], horizontalPadding)
    }

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
        // Typographic apostrophes
        text.replacingOccurrences(of: "'", with: "ʼ")
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
            .custom("DM Sans", size: size).weight(.semibold)
        case .title2:
            .custom("DM Sans", size: size).weight(.semibold)
        case .subtitle:
            .custom("DM Sans", size: size).weight(.semibold)
        case .pillarTitle:
            .custom("DM Sans", size: size).weight(.bold)
        case .pillarSubtitle:
            .custom("DM Sans", size: size).weight(.regular)
        }
    }

    private var size: CGFloat {
        let screenWidth = geometry.size.width
        let isSmallScreen = geometry.size.height <= 700

        switch type {
        case .title:
            return screenWidth * 0.069
        case .title2:
            return 18
        case .subtitle:
            return screenWidth * (isSmallScreen ? 0.04 : 0.035)
        case .pillarTitle:
            return 14
        case .pillarSubtitle:
            return 14
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
        calculateStoryTimeDescription(unitSeparator: .nbsp, componentSeparator: .nbsp)
    }

    /// Return normal text when displaying the time for sharing
    var storyTimeDescriptionForSharing: String {
        calculateStoryTimeDescription()
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

// MARK: - Story Title / Subtitle Container

struct PodcastCoverContainer<Content: View>: View {
    private var content: () -> Content
    private let alignment: Alignment
    private let geometry: GeometryProxy

    let topPaddingSmall = 0.03
    let topPaddingLarge = 0.045
    let smallDeviceHeight = 700.0

    init(geometry: GeometryProxy, alignment: Alignment = .top, @ViewBuilder _ content: @escaping () -> Content) {
        self.geometry = geometry
        self.content = content
        self.alignment = alignment
    }

    var body: some View {
        // Scale the top padding to fit better on smaller screens
        let padding = geometry.size.height <= smallDeviceHeight ? topPaddingSmall : topPaddingLarge
        let topPadding = geometry.size.height * padding
        VStack(spacing: 0) {
            switch alignment {
            case .top:
                content()
                Spacer()
            case .center:
                Spacer()
                content()
                Spacer()
            case .bottom:
                Spacer()
                content()
            default:
                content()
            }
        }.frame(width: geometry.size.width).padding(.top, topPadding)
    }
}

/// This is a wrapped around a VStack that keeps consistent spacing and top padding
struct StoryLabelContainer<Content: View>: View {
    private var content: () -> Content

    let topPadding: Double?
    private let geometry: GeometryProxy

    init(topPadding: Double? = nil, geometry: GeometryProxy, @ViewBuilder _ content: @escaping () -> Content) {
        self.topPadding = topPadding
        self.geometry = geometry
        self.content = content
    }

    var body: some View {
        // Try to reduce the label distance based on the screen height, but keep
        let labelSpacing = (geometry.size.height * 0.013).clamped(to: 0..<10)
        let topPadding = topPadding ?? (geometry.size.height * 0.054).clamped(to: 10..<60)
        VStack(spacing: labelSpacing) {
            content()
        }.padding(.top, topPadding)
    }
}

extension String {
    /// Limit the string to given length or truncate it with ...
    func limited(to len: Int) -> String {
        // If the length is less than the max, then allow it
        // or if the string isn't going to go too much over the limit allow it
        if count < len || count - len < 5 {
            return self
        }

        return self.prefix(len).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

// MARK: - 2023 background

struct StoryGradient: View {
    let geometry: GeometryProxy
    var plus: Bool = false

    var body: some View {
        Rectangle()
        .foregroundColor(.clear)
        .frame(width: geometry.size.height * 0.6, height: geometry.size.height * 0.6)
        .background(
            LinearGradient(
                stops: gradient,
                startPoint: UnitPoint(x: 0.49, y: 0.11),
                endPoint: UnitPoint(x: 0.49, y: 0.98)
            )
        )
        .cornerRadius(geometry.size.height * 0.6)
        .blur(radius: geometry.size.height * 0.13)
        .opacity(0.6)
    }

    private var gradient: [Gradient.Stop] {
        plus ? plusGradient : normalGradient
    }

    private var plusGradient: [Gradient.Stop] {
        [
            Gradient.Stop(color: Color(red: 0.91, green: 0.35, blue: 0.26), location: 0.00),
            Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 0.61),
            Gradient.Stop(color: .black, location: 1.00),
        ]
    }

    private var normalGradient: [Gradient.Stop] {
        [
            Gradient.Stop(color: Color(red: 0.25, green: 0.11, blue: 0.92), location: 0.00),
            Gradient.Stop(color: Color(red: 0.68, green: 0.89, blue: 0.86), location: 0.61),
            Gradient.Stop(color: Color(red: 0.87, green: 0.91, blue: 0.53), location: 1.00),
        ]
    }
}
