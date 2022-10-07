import UIKit

class WhatsNewThemeableImageView: ThemeableImageView {
    var originalName: String
    required init(imageName: String) {
        originalName = imageName
        super.init(frame: CGRect.zero)
        imageNameFunc = themedImageName
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("WhatsNewThemeableImageView init(coder) not implemented")
    }

    func themedImageName() -> String {
        switch Theme.sharedTheme.activeTheme {
        case .dark, .extraDark:
            return originalName + "_dark"
        case .light, .classic:
            return originalName
        case .electric:
            return originalName + "_electricity"
        case .indigo:
            return originalName + "_indigo"
        case .radioactive:
            return originalName + "_radioactive"
        case .rosé:
            return originalName + "_rose"
        case .contrastDark:
            return originalName + "_contrastDark"
        case .contrastLight:
            return originalName + "_contrastLight"
        }
    }
}
