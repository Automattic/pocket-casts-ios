import SwiftUI

struct TimelineEvent: Hashable {
    var iconName: String
    var title: String
    var detail: String
    var date: Date
}

extension TimelineEvent {
    static var sampleEvents: [TimelineEvent] = [
        TimelineEvent(iconName: "unlocked-large", title: "Today", detail: "Get access to Folders, Shuffle, Bookmarks, and exclusive content", date: Date.now),
        TimelineEvent(iconName: "mail", title: "Day 24", detail: "We’ll notify you about your trial ending.", date: Date.now + 3600),
        TimelineEvent(iconName: "star_empty", title: "Day 31", detail: "You’ll be charged on September 31th. Cancel anytime before.", date: Date.now + (3600 * 2))
    ]
}

struct UpgradeTimelineView: View {

    @EnvironmentObject var theme: Theme

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
                    .frame(width: 44, height: 44)
                    .cornerRadius(44)
                Image(iconName)
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(theme.primaryUi01)
            }
            .background() {
                if index != events.count - 1 {
                    ZStack {
                        Rectangle()
                            .frame(width: 7, height: 150)
                            .offset(x: 0, y: 75 + 22)
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
                HStack(alignment: .top) {
                    iconRow(iconName: event.iconName, index: index)
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText01)
                        Text(event.detail)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText02)
                    }
                    .padding(.bottom, 32)
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
