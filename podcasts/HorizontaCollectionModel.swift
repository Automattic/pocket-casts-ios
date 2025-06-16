import Foundation
import SwiftUI

class HorizontalCollectionModel: ObservableObject {

    @Published var colors: [Color] = [.blue, .green, .yellow, .orange, .pink, .purple, .cyan, .brown, .indigo]

    var list: [[Color?]] {
        return colors.pairs()
    }
}

extension Color: @retroactive Identifiable {

    public var id: String {
        return description
    }
}
