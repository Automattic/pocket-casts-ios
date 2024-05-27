import SwiftUI

struct UpNextHistoryView: View {

    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Hello, World!")
                Spacer()
            }
            Spacer()
        }
        .navigationTitle("Up Next History")
            .applyDefaultThemeOptions()
    }
}

#Preview {
    UpNextHistoryView()
}
