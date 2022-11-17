import Foundation
import SwiftUI

class OnboardingHostingViewController<Content>: UIHostingController<Content> where Content: View {
    var navBarIsHidden: Bool = false
    var iconTintColor: UIColor = AppTheme.colorForStyle(.secondaryIcon01)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = navBarIsHidden
        navigationController?.navigationBar.tintColor = iconTintColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = iconTintColor
    }
}
