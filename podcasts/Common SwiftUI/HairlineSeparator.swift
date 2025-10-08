import SwiftUI

/// A separator which is drawn as 1 physical pixel. This mirrors the separator used in UITableView
struct HairlineSeparator: View {
    var color: Color = Color(UIColor.separator)

    @Environment(\.displayScale) private var scale

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1 / scale)          // 1 physical pixel
            .allowsHitTesting(false)
    }
}
