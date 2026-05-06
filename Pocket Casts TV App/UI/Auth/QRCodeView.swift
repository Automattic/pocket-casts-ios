import SwiftUI

struct QRCodeView: View {

    enum Layout {
        static let qrSize = CGFloat(240)
    }

    var body: some View {
        ZStack {
            Image(ImageResource.qrCode)
                .resizable()
                .frame(width: Layout.qrSize, height: Layout.qrSize)
        }
        .padding()
        .background(.white)
    }
}

#Preview {
    QRCodeView()
}
