import SwiftUI

struct RoundProgressView: View {

    let trackColor: Color
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor.opacity(0.3))
                    .frame(height: 6)
                Capsule()
                    .fill(trackColor)
                    .frame(width: max(0, geo.size.width * progress), height: 6)
            }
        }
        .frame(height: 6)
    }
}
