import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 17.0, *)
struct SleepTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerActivityAttributes.self) { context in
            SleepTimerLockScreenView(context: context)
                .activityBackgroundTint(SleepTimerLiveActivityStyle.backgroundColor)
                .activitySystemActionForegroundColor(SleepTimerLiveActivityStyle.primaryTextColor)
                .widgetURL(URL(string: "pktc://show_player"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SleepTimerIcon(size: 24)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .center, spacing: 2) {
                        Text(L10n.sleepTimer)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(SleepTimerLiveActivityStyle.secondaryTextColor)
                        SleepTimerCountdown(endDate: context.state.timerEndDate, font: .title3.monospacedDigit().weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        SleepTimerEpisodeText(
                            episodeTitle: context.attributes.episodeTitle,
                            podcastTitle: context.attributes.podcastTitle
                        )
                        Spacer(minLength: 8)
                        SleepTimerExtendButton()
                    }
                }
            } compactLeading: {
                SleepTimerIcon(size: 19)
                    .frame(width: 28, height: 28)
                    .padding(.leading, 4)
            } compactTrailing: {
                SleepTimerCountdown(endDate: context.state.timerEndDate, font: .caption2.monospacedDigit().weight(.semibold))
                    .frame(width: 48, alignment: .center)
                    .padding(.trailing, 4)
            } minimal: {
                SleepTimerIcon(size: 16)
            }
            .widgetURL(URL(string: "pktc://show_player"))
            .keylineTint(SleepTimerLiveActivityStyle.accentColor)
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct SleepTimerLockScreenView: View {
    let context: ActivityViewContext<SleepTimerActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            SleepTimerIcon(size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.sleepTimer)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(SleepTimerLiveActivityStyle.secondaryTextColor)

                SleepTimerCountdown(endDate: context.state.timerEndDate, font: .title2.monospacedDigit().weight(.bold))
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            SleepTimerExtendButton()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct SleepTimerCountdown: View {
    let endDate: Date
    let font: Font

    var body: some View {
        let startDate = min(Date(), endDate)

        Text(timerInterval: startDate ... endDate, countsDown: true)
            .font(font)
            .foregroundStyle(SleepTimerLiveActivityStyle.primaryTextColor)
            .multilineTextAlignment(.leading)
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct SleepTimerEpisodeText: View {
    let episodeTitle: String?
    let podcastTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let episodeTitle, !episodeTitle.isEmpty {
                Text(episodeTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(SleepTimerLiveActivityStyle.primaryTextColor)
                    .lineLimit(1)
            }

            if let podcastTitle, !podcastTitle.isEmpty {
                Text(podcastTitle)
                    .font(.caption2)
                    .foregroundStyle(SleepTimerLiveActivityStyle.secondaryTextColor)
                    .lineLimit(1)
            }
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct SleepTimerExtendButton: View {
    var body: some View {
        Button(intent: ExtendSleepTimerLiveActivityIntent()) {
            Text(L10n.sleepTimerAdd5Mins)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundStyle(SleepTimerLiveActivityStyle.buttonTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SleepTimerLiveActivityStyle.buttonBackgroundColor, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct SleepTimerIcon: View {
    var size: CGFloat = 28

    var body: some View {
        Image("logo_white_small_transparent")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

private enum SleepTimerLiveActivityStyle {
    static let backgroundColor = Color.widgetBlack
    static let accentColor = Color.widgetRedLight
    static let primaryTextColor = Color.white
    static let secondaryTextColor = Color.white.opacity(0.68)
    static let buttonBackgroundColor = Color.widgetRedLight
    static let buttonTextColor = Color.white
}
