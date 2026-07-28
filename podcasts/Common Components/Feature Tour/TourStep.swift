import Foundation

struct TourStep {
    var title = ""
    var detail = ""
    var buttonTitle = ""
    var featureHighlight: UIView?
    var spotlight: TourSpotlight?
    var yTranslation: CGFloat = 0
    var anchorToTop = false
}
