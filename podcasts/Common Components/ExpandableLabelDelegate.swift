import UIKit

@MainActor
protocol ExpandableLabelDelegate: NSObjectProtocol {
    func willExpandLabel(_ label: UIView)
    func didExpandLabel(_ label: UIView)

    func willCollapseLabel(_ label: UIView)
    func didCollapseLabel(_ label: UIView)

    func linkTapped(url: URL)
}
