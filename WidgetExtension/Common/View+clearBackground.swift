import SwiftUI

extension View {
    func clearBackground() -> some View {
        return self.containerBackground(.clear, for: .widget)
    }
}
