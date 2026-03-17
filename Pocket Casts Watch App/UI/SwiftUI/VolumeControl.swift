import SwiftUI

struct VolumeControl: WKInterfaceObjectRepresentable {
    var tint: Color

    func makeWKInterfaceObject(context: Self.Context) -> WKInterfaceVolumeControl {
        let origin: WKInterfaceVolumeControl.Origin = SourceManager.shared.isWatch() ? .local : .companion
        let view = WKInterfaceVolumeControl(origin: origin)
        view.focus()
        view.setTintColor(UIColor(tint))
        return view
    }

    func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceVolumeControl, context: WKInterfaceObjectRepresentableContext<VolumeControl>) {
        wkInterfaceObject.setTintColor(UIColor(tint))
    }
}
