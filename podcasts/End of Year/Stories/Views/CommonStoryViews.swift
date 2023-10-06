import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

/// A label used in the end of year stories that provides consistent styling
/// This preprocesses the text to improve the typography
struct StoryLabel: View {
    private let text: String
    private let highlights: [String]?
    private let type: StoryLabelType
    private let geometry: GeometryProxy?
    private let color: Color

    init(_ text: String, highlighting: [String]? = nil, for type: StoryLabelType, color: Color = .white, geometry: GeometryProxy? = nil) {
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
        text.preventWidows().replacingOccurrences(of: "'", with: "ʼ")
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
            .custom("DM Sans", size: (geometry?.size.height ?? 759) * 0.035).weight(.semibold)
        case .title2:
            .custom("DM Sans", size: 18).weight(.semibold)
        case .subtitle:
            .custom("DM Sans", size: (geometry?.size.height ?? 759) * 0.018).weight(.semibold)
        case .pillarTitle:
            .custom("DM Sans", size: 14).weight(.bold)
        case .pillarSubtitle:
            .custom("DM Sans", size: 14).weight(.regular)
        }
    }

    private var size: CGFloat {
        let iPhone15DefaultHeight: CGFloat = 759
        let screenHeight = geometry?.size.height ?? iPhone15DefaultHeight

        switch type {
        case .title:
            return screenHeight * 0.035
        case .title2:
            return 18
        case .subtitle:
            return screenHeight * 0.018
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

    /// For displaying units above the category pillars, allow the time components to be broken up across
    /// multiple lines, but don't let the unit (10 minutes) itself to be broken up
    var storyTimeDescriptionForPillars: String {
        calculateStoryTimeDescription(unitSeparator: .nbsp, componentSeparator: "\n")
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

// MARK: - Podcast Perspective

/// Apply a perspective to the podcasts cover
struct PodcastCoverPerspective: ViewModifier {
    static let rotationAngle = Angle(degrees: -45)
    static let scale = CGSize(width: 1.0, height: 0.5)

    /// Allows overriding of the scaleEffect anchor property, defaults to .center
    let scaleAnchor: UnitPoint

    init(scaleAnchor: UnitPoint = .center) {
        self.scaleAnchor = scaleAnchor
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(Self.rotationAngle, anchor: .center)
            .scaleEffect(Self.scale, anchor: scaleAnchor)
    }
}

struct PodcastPerspectiveRotator<Cover: View>: View {
    let content: Cover

    init(_ content: Cover) {
        self.content = content
    }

    @State private var size: CGSize = .zero

    var body: some View {
        let scale = PodcastCoverPerspective.scale
        let angle = PodcastCoverPerspective.rotationAngle

        // Rotate the frame, and compute the smallest integral frame that contains it
        let calculatedFrame = CGRect(origin: .zero, size: size)
            .offsetBy(dx: -size.width * 0.5, dy: -size.height * 0.5)
            .applying(.init(rotationAngle: CGFloat(angle.radians)))
            .applying(.init(scaleX: scale.width, y: scale.height))
            .integral

        return content
            .fixedSize()
            .captureSize(in: $size)
            .modifier(PodcastCoverPerspective())
            .frame(width: calculatedFrame.width, height: calculatedFrame.height)
    }
}

private struct SizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func applyPodcastCoverPerspective() -> some View {
        PodcastPerspectiveRotator(self)
    }

    func captureSize(in binding: Binding<CGSize>) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: SizeKey.self, value: proxy.size)
        }).onPreferenceChange(SizeKey.self) { size in binding.wrappedValue = size }
    }
}

// MARK: - Story Title / Subtitle Container

struct PodcastCoverContainer<Content: View>: View {
    private var content: () -> Content
    private let geometry: GeometryProxy

    let topPaddingSmall = 0.03
    let topPaddingLarge = 0.045
    let smallDeviceHeight = 700.0

    init(geometry: GeometryProxy, @ViewBuilder _ content: @escaping () -> Content) {
        self.geometry = geometry
        self.content = content
    }

    var body: some View {
        // Scale the top padding to fit better on smaller screens
        let padding = geometry.size.height <= smallDeviceHeight ? topPaddingSmall : topPaddingLarge
        let topPadding = geometry.size.height * padding
        VStack(spacing: 0) {
            content()
            Spacer()
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

// MARK: - Podcast Stack Views

/// This is a view that displays a single podcast cover on top and the podcast colors below it
/// in a stacked view
struct PodcastStackView: View {
    let podcasts: [Podcast]
    let topPadding: Double?
    let geometry: GeometryProxy

    let topPaddingSmall = 0.10
    let topPaddingLarge = 0.0
    let smallDeviceHeight = 700.0

    init(podcasts: [Podcast], topPadding: Double? = nil, geometry: GeometryProxy) {
        self.podcasts = podcasts
        self.topPadding = topPadding
        self.geometry = geometry
    }

    var body: some View {
        let isSmall = geometry.size.height <= smallDeviceHeight
        let padding = isSmall ? topPaddingSmall : topPaddingLarge
        let topPadding = geometry.size.height * padding

        let size = geometry.size.width * Constants.coverSize
        Spacer()
        VStack(spacing: 0) {
            if podcasts.count == 1 {
                showSinglePodcastCover(podcasts[0], size: size)
            } else {
                showMultipleCovers(size: size)
            }
        }
        .padding(.top, topPadding)
    }

    @ViewBuilder
    private func showSinglePodcastCover(_ podcast: Podcast, size: Double) -> some View {
        PodcastCover(podcastUuid: podcast.uuid, big: true)
            .modifier(StackModifier(size: size))
            .zIndex(2)

        Rectangle()
            .foregroundColor(ColorManager.lightThemeTintForPodcast(podcast).color)
            .modifier(BigCoverShadow())
            .modifier(StackModifier(size: size))
            .zIndex(1)

        Rectangle()
            .foregroundColor(ColorManager.darkThemeTintForPodcast(podcast).color)
            .modifier(BigCoverShadow())
            .modifier(StackModifier(size: size))
            .zIndex(0)
    }

    @ViewBuilder
    private func showMultipleCovers(size: Double) -> some View {
        ForEach(0..<Constants.maxStackCount, id: \.self) {
            podcastCover($0)
                .modifier(StackModifier(size: size))
                .zIndex(Double(Constants.maxStackCount - $0))
        }
    }

    @ViewBuilder
    func podcastCover(_ index: Int) -> some View {
        let podcast = podcasts[safe: index] ?? podcasts[0]
        PodcastCover(podcastUuid: podcast.uuid, big: true)
    }

    private enum Constants {
        static let coverSize = 0.6
        static let maxStackCount = 3
    }

    /// Applies the frame and stacking modifier
    private struct StackModifier: ViewModifier {
        let size: Double

        func body(content: Content) -> some View {
            content
                .frame(width: size, height: size)
                .applyPodcastCoverPerspective()
                .padding(.top, size * -0.55)
        }
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

extension NSLocale {
    static var isCurrentLanguageEnglish: Bool {
        // Get the current language from the user defaults, or default to checking the locale if that fails
        let currentLanguageCode = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first ?? NSLocale.autoupdatingCurrent.languageCode
        guard let currentLanguageCode else { return false }

        // Support multiple english language checks en-US, en-GB
        return currentLanguageCode.hasPrefix("en")
    }
}
