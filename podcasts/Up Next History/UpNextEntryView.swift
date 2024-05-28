import SwiftUI

struct UpNextEntryView: View {
    @EnvironmentObject var theme: Theme
    var body: some View {
        Text("Hello, World!")
            .navigationTitle("Up Next History")
            .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextEntryView()
}
