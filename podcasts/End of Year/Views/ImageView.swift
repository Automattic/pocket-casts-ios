import SwiftUI
import Kingfisher

/// A SwiftUI representation of UIImageView
///
/// This is necessary because `Image` does not render correctly
/// when taking screenshots of it — the image doesn't appear.
struct ImageView: UIViewRepresentable {
    let url: URL

    init(_ url: URL) {
        self.url = url
    }

    func makeUIView(context: Context) -> UIImageView {
        let v = ImageViewWithFixedIntrinsicContentSize()

        return v
    }

    func updateUIView(_ uiImage: UIImageView, context: Context) {
        uiImage.kf.setImage(with: url)
    }
}

private class ImageViewWithFixedIntrinsicContentSize: UIImageView {
    override var intrinsicContentSize: CGSize {
        return .init(width: 76, height: 76)
    }
}
