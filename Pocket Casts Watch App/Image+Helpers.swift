import Foundation
import Kingfisher
import SwiftUI

extension Image {
    static var placeholder: some View {
        Image("noartwork")
            .resizable()
    }
}

struct CachedImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 5

    var body: some View {
        KFImage
            .url(url)
            .targetCache(WatchImageHelper.shared.mainCache)
            .placeholder { _ in
                Image.placeholder
            }
            .resizable()
            .scaledToFit()
            .cornerRadius(cornerRadius)
    }
}
