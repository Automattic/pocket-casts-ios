import ActivityKit
import PocketCastsUtils
import SwiftUI
import WidgetKit

struct SleepTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerActivityAttributes.self) { context in
            SleepTimerLockScreenView(context: context)
                // Fully transparent, so the content sits directly on the wallpaper like
                // the other widgets do via `clearBackground()`.
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(SleepTimerLiveActivityStyle.primaryTextColor)
                .widgetURL(URL(string: "pktc://show_player"))
        } dynamicIsland: { context in
            DynamicIsland {
                // A single full-width row mirrors the Lock Screen layout; splitting it across
                // leading/center/trailing regions leaves too little width for the extend button.
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        SleepTimerIcon(size: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.sleepTimer)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .textCase(.uppercase)
                                .foregroundStyle(SleepTimerLiveActivityStyle.secondaryTextColor)
                            SleepTimerCountdown(state: context.state, font: .title3.monospacedDigit().weight(.semibold))
                        }
                        .lineLimit(1)

                        Spacer(minLength: 8)

                        SleepTimerExtendButton()
                    }
                }
            } compactLeading: {
                SleepTimerIcon(size: 19)
                    .frame(width: 28, height: 28)
                    .padding(.leading, 4)
            } compactTrailing: {
                SleepTimerCountdown(state: context.state, font: .caption2.monospacedDigit().weight(.semibold))
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

private struct SleepTimerLockScreenView: View {
    let context: ActivityViewContext<SleepTimerActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            SleepTimerIcon(size: CommonWidgetHelper.iconSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.sleepTimer)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(SleepTimerLiveActivityStyle.secondaryTextColor)

                SleepTimerCountdown(state: context.state, font: .title2.monospacedDigit().weight(.bold))
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            SleepTimerExtendButton()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct SleepTimerCountdown: View {
    let state: SleepTimerActivityAttributes.ContentState
    let font: Font

    var body: some View {
        Group {
            if state.isPaused {
                // The sleep timer doesn't tick while playback is paused, so show a fixed
                // time rather than letting the system run the countdown down to zero.
                Text(TimeFormatter.shared.playTimeFormat(time: state.remaining))
            } else {
                let startDate = min(Date(), state.timerEndDate)
                Text(timerInterval: startDate ... state.timerEndDate, countsDown: true)
            }
        }
        .font(font)
        .foregroundStyle(SleepTimerLiveActivityStyle.primaryTextColor)
        .multilineTextAlignment(.leading)
    }
}

private struct SleepTimerExtendButton: View {
    var body: some View {
        Button(intent: ExtendSleepTimerLiveActivityIntent()) {
            Text(L10n.sleepTimerAdd5Mins)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        // The widget extension has no accent color, so an untinted bordered button picks up
        // the system default and all but disappears over a wallpaper.
        .buttonStyle(.bordered)
        .tint(SleepTimerLiveActivityStyle.primaryTextColor)
    }
}

private struct SleepTimerIcon: View {
    var size: CGFloat = 28

    var body: some View {
        Image("logo_white_small_transparent")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(SleepTimerLiveActivityStyle.primaryTextColor)
    }
}

private enum SleepTimerLiveActivityStyle {
    static let accentColor = Color.widgetRedLight
    // The activity has no background of its own, so the text has to adapt to the wallpaper.
    static let primaryTextColor = Color.primary
    static let secondaryTextColor = Color.secondary
}

@available(iOSApplicationExtension 17.0, *)
#Preview("Sleep Timer", as: .content, using: SleepTimerActivityAttributes()) {
    SleepTimerLiveActivityWidget()
} contentStates: {
    SleepTimerActivityAttributes.ContentState(
        timerEndDate: Date().addingTimeInterval(14.minutes),
        remaining: 14.minutes,
        isPaused: false
    )
    SleepTimerActivityAttributes.ContentState(
        timerEndDate: Date().addingTimeInterval(14.minutes),
        remaining: 14.minutes,
        isPaused: true
    )
}
