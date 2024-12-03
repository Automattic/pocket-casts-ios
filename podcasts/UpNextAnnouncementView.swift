import SwiftUI

struct UpNextAnnouncementView: View {
    @EnvironmentObject var theme: Theme

    @State private var show = false

    var body: some View {
        Image("up-next-shuffle-sheet")
            .foregroundStyle(theme.primaryIcon01)
            .opacity(show ? 1 : 0)
            .animation(
                .linear(duration: 0.6)
                .delay(TimeInterval(0.6)),
                value: show
            )
            .onAppear {
                show.toggle()
            }
    }
}

struct UpNextAnnouncementView_Previews: PreviewProvider {
    static var previews: some View {
        UpNextAnnouncementView()
            .setupDefaultEnvironment()
            .previewLayout(.fixed(width: 120, height: 120))
    }
}
