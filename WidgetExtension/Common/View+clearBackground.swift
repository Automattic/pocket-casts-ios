import SwiftUI

extension View {
    func clearBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.containerBackground(.clear, for: .widget)
        } else {
            return self
        }
    }
}
