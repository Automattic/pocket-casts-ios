import SwiftUI

struct TimelineEvent: Hashable {
    var iconName: String
    var title: String
    var detail: String
}

extension TimelineEvent {
    static var sampleEvents: [TimelineEvent] = [
        TimelineEvent(iconName: "unlocked-large", title: "Today", detail: "Get access to Folders, Shuffle, Bookmarks, and exclusive content"),
        TimelineEvent(iconName: "mail", title: "Day 24", detail: "We’ll notify you about your trial ending."),
        TimelineEvent(iconName: "star_empty", title: "Day 31", detail: "You’ll be charged on September 31th. Cancel anytime before.")
    ]
}

struct UpgradeTimelineView: View {

    @EnvironmentObject var theme: Theme

    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 44

    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 24

    @ScaledMetric(relativeTo: .body) private var timelineBarHeight: CGFloat = 150

    @ScaledMetric(relativeTo: .body) private var timelineBarWidth: CGFloat = 7

    let events: [TimelineEvent]

    private func opacityValueForIndex(_ index: Int) -> Double {
        guard events.isEmpty == false else {
            return 0
        }
        return 1.0 - (Double(index) * (0.6 / Double(events.count)))
    }

    @ViewBuilder
    func iconRow(iconName: String, index: Int) -> some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .center) {
                Circle()
                    .inset(by: index == 0 ? 0 : -0.2)
                    .fill(theme.primaryInteractive01)
                    .opacity(opacityValueForIndex(index))
                    .frame(width: circleSize, height: circleSize)
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                    .foregroundColor(theme.primaryUi01)
            }
            .background() {
                if index != events.count - 1 {
                    ZStack {
                        Rectangle()
                            .frame(width: timelineBarWidth, height: timelineBarHeight)
                            .offset(x: 0, y: (timelineBarHeight / 2.0) + (circleSize / 2.0) - (index == 0 ? 1 : 0))
                            .foregroundStyle(LinearGradient(colors: [
                                theme.primaryInteractive01.opacity(opacityValueForIndex(index)),
                                theme.primaryInteractive01.opacity(opacityValueForIndex(index+1)),
                            ], startPoint: UnitPoint.top, endPoint: UnitPoint.bottom))
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(zip(events.indices, events)), id: \.0) { index, event in
                HStack(alignment: .top, spacing: 14) {
                    iconRow(iconName: event.iconName, index: index)
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(size: 15, style: .body, weight: .bold)
                            .foregroundColor(theme.primaryText01)
                        Text(event.detail)
                            .font(size: 15, style: .body, weight: .medium)
                            .foregroundColor(theme.primaryText02)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.bottom, index != events.count - 1 ? 48 : 0)
                    .padding(.horizontal, 14)
                    Spacer()
                }
                .clipped()
            }
        }
    }
}

#Preview {
    UpgradeTimelineView(events: TimelineEvent.sampleEvents).setupDefaultEnvironment()
}
