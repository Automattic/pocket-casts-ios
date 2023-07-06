import SwiftUI

struct AutoplayWhatsNewHeader: View {
    var body: some View {
        LinearGradient(colors: [.init(hex: "03A9F4"), .init(hex: "50D0F1")], startPoint: .top, endPoint: .bottom)

        ZStack {
            Circle()
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)

            Image("whatsnew_autoplay")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
        }
    }
}

struct AutoplayWhatsNewHeader_Previews: PreviewProvider {
    static var previews: some View {
        AutoplayWhatsNewHeader()
    }
}
