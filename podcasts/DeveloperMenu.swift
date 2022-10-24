import SwiftUI
import PocketCastsServer

struct DeveloperMenu: View {
    var body: some View {
        VStack {
            Button {
                ServerSettings.syncingV2Token = "badToken"
            } label: {
                Text("Corrupt Sync Login Token")
                    .padding()
                    .overlay(
                          RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                      )
            }
        }
        .padding()
    }
}

struct DeveloperMenu_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMenu()
    }
}
