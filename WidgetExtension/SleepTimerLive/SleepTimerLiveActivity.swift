import SwiftUI
import ActivityKit
import WidgetKit
import PocketCastsUtils

@available(iOS 16.2, *)
struct SleepTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerLiveActivityAttributes.self) { context in
            SleepTimerLiveActivityContent(currentTime: context.state.currentTime, progress: context.state.progress)
        } dynamicIsland: { attributes in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AppLogo(size: 35)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    MinimalProgressBar(progress: attributes.state.progress,
                                       currentTime: attributes.state.currentTime,
                                       size: 35)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // expanded content
                }
                DynamicIslandExpandedRegion(.center) {
                    // center content
                }
            } compactLeading: {
                AppLogo(size: 24)
            } compactTrailing: {
                MinimalProgressBar(progress: attributes.state.progress,
                                   currentTime: attributes.state.currentTime,
                                   size: 24)
            } minimal: {
                MinimalProgressBar(progress: attributes.state.progress,
                                   currentTime: attributes.state.currentTime,
                                   size: 24)
            }
        }
    }
}

@available(iOS 16.2, *)
struct SleepTimerLiveActivityContent: View {
    let currentTime: TimeInterval
    let progress: Double

    var body: some View {
        VStack {
            HStack {
                Text("Sleep Timer")
                    .font(.system(size: 13))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                Spacer()
                AppLogo(size: 24)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("\(TimeFormatter.shared.playTimeFormat(time: currentTime))")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    HorizontalProgressBar(progress: progress)
                        .frame(height: 8)
                }
                Spacer()
            }
        }
        .padding(16)
        .activityBackgroundTint(.clear)
        .activitySystemActionForegroundColor(.black)
    }
}

@available(iOS 16.2, *)
struct HorizontalProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let boxWidth = frame.width * progress

            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.red.opacity(0.5))

            RoundedRectangle(cornerRadius: 20)
                .frame(width: boxWidth)
                .foregroundColor(.red)
        }
    }
}

struct MinimalProgressBar: View {
    let progress: Double
    let currentTime: TimeInterval
    let size: CGFloat

    var body: some View {
        ProgressView(value: progress, total: 1) {
//            Text("\(TimeFormatter.shared.playTimeFormat(time: currentTime))")
        }.frame(width: size, height: size)
            .progressViewStyle(.circular)
            .tint(.red)
    }
}

struct AppLogo: View {
    let size: CGFloat
    var body: some View {
        Image(uiImage: UIImage(named: "logo_red_small")!)
            .resizable().frame(width: size, height: size)
            .scaledToFit()
            .clipShape(.circle)
    }
}
