import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {

    let url: String
    @State var uiImage: UIImage?

    private let context = CIContext()

    enum Layout {
        static let qrSize = CGFloat(240)
    }

    func generateQRImage() async {
        var resultImage: UIImage?
        let qrCodeGenerator = CIFilter.qrCodeGenerator()
        qrCodeGenerator.message = url.data(using: .ascii)!
        qrCodeGenerator.correctionLevel = "H"
        if let outputImage = qrCodeGenerator.outputImage {
            // Scale up so the QR code stays crisp on a TV screen
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                resultImage = UIImage(cgImage: cgImage)
            }
        }
        await MainActor.run {
            uiImage = resultImage
        }
    }

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: Layout.qrSize, height: Layout.qrSize)
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(.white)
        .task {
            await generateQRImage()
        }
    }
}

#Preview {
    QRCodeView(url: "https://pocketcasts.net/pair")
}
