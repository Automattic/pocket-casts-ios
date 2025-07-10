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

    var circle: some View {
        ZStack {
            Rectangle()
                .fill(theme.primaryInteractive01)
            Rectangle()
                .inset(by: 0.5)
                .stroke(theme.primaryInteractive01)
        }
    }

    @ViewBuilder
    func iconRow(iconName: String, index: Int) -> some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .center) {
                circle
                    .opacity(1.0 - (Double(index) * 0.2))
                    .frame(width: circleSize, height: circleSize)
                    .cornerRadius(circleSize)
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
                            .offset(x: 0, y: (timelineBarHeight / 2.0) + (circleSize / 2.0))
                            .foregroundStyle(LinearGradient(colors: [
                                theme.primaryInteractive01.opacity(1.0 - (Double(index) * 0.2)),
                                theme.primaryInteractive01.opacity(1.0 - (Double(index + 1) * 0.2))
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
                    .padding(.bottom, 32)
                    .padding(.horizontal, 14)
                    Spacer()
                }
                .clipped()
            }
            Spacer()
        }
    }
}

#Preview {
    UpgradeTimelineView(events: TimelineEvent.sampleEvents).setupDefaultEnvironment()
}
