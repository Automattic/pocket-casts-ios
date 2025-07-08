import SwiftUI

struct TimelineEvent: Hashable {
    var iconName: String
    var title: String
    var detail: String
    var date: Date
}

extension TimelineEvent {
    static var sampleEvents: [TimelineEvent] = [
        TimelineEvent(iconName: "lock", title: "Today", detail: "Get access to Folders, Shuffle, Bookmarks, and exclusive content", date: Date.now),
        TimelineEvent(iconName: "mail", title: "Day 24", detail: "We’ll notify you about your trial ending.", date: Date.now + 3600),
        TimelineEvent(iconName: "star", title: "Day 31", detail: "You’ll be charged on September 31th. Cancel anytime before.", date: Date.now + (3600 * 2))
    ]
}

struct UpgradeTimelineView: View {

    @EnvironmentObject var theme: Theme

    let events: [TimelineEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(zip(events.indices, events)), id: \.0) { index, feature in
                HStack(alignment: .top) {
                    ZStack(alignment: .top) {
                        ZStack(alignment: .center) {
                            Circle().frame(width: 43, height: 43)
                                .foregroundColor(theme.primaryInteractive01)
                            Image(systemName: feature.iconName)
                                .renderingMode(.template)
                                .frame(width: 24, height: 24)
                                .foregroundColor(theme.primaryUi01)
                        }
                        .background() {
                            if index != events.count - 1 {
                                ZStack {
                                    Rectangle()
                                        .frame(width: 7, height: 150)
                                        .offset(x: 0, y: 75)
                                        .foregroundColor(theme.primaryInteractive01)
                                }
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading) {
                        Text(feature.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText01)
                        Text(feature.detail)
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
