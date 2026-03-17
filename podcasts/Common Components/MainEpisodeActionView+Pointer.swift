import Foundation

extension MainEpisodeActionView: UIPointerInteractionDelegate {
    func enablePointerInteraction() {
        addInteraction(UIPointerInteraction(delegate: self))
    }

    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        UIPointerStyle(effect: .automatic(.init(view: self)))
    }
}
