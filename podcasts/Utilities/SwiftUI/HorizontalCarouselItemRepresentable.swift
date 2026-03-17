import SwiftUI

protocol HorizontalCarouselItemRepresentable: RawRepresentable, CaseIterable, Identifiable where RawValue == String, Self.AllCases: RandomAccessCollection {
    var title: String { get }
    var text: String { get }
    var image: String { get }
    var backgroundColor: Color { get }
    var titleColor: Color { get }
    var titleSize: CGFloat { get }
    var textColor: Color { get }
    var textSize: CGFloat { get }
}

extension HorizontalCarouselItemRepresentable {
    var id: Self {
        return self
    }
}
