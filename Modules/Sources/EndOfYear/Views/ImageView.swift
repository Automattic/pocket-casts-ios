import SwiftUI
import Kingfisher

/// A SwiftUI representation of UIImageView
///
/// This is necessary because `Image` does not render correctly
/// when taking screenshots of it — the image doesn't appear.
public struct ImageView: UIViewRepresentable {
    var image: UIImage?

    public init(image: UIImage? = nil) {
        self.image = image
    }

    public func makeUIView(context: Context) -> UIImageView {
        let v = UIImageView()

        v.setContentHuggingPriority(.defaultLow, for: .vertical)
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return v
    }

    public func updateUIView(_ uiImage: UIImageView, context: Context) {
        uiImage.image = image
    }
}
