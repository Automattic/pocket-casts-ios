import Foundation
import SwiftUI

class SearchResultsViewController: OnboardingHostingViewController<Text> {
    init() {
        super.init(rootView: Text("New Search"))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
