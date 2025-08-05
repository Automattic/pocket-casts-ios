import SwiftUI

struct NavigationContainer<Content: View>: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
}

    var body: some View {
        NavigationStack {
            content()
        }
    }
}
