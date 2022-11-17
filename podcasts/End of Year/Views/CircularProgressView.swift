import SwiftUI
import PocketCastsServer

struct CircularProgressView: View {
    @ObservedObject private var model = SyncYearListeningProgress.shared

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.white.opacity(0.5),
                    lineWidth: 6
                )
            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
