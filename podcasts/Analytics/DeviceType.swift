import AVFoundation
#if !os(watchOS)
import UIKit
import PocketCastsUtils
#endif

enum DeviceType: String, AnalyticsDescribable {
    case phone, tablet, carplay

    var analyticsDescription: String { rawValue }

    static var current: DeviceType {
        #if os(watchOS)
        return .phone
        #else
        if isCarPlayConnected() { return .carplay }
        return UIDevice.current.isiPad() ? .tablet : .phone
        #endif
    }

    #if !os(watchOS)
    private static func isCarPlayConnected() -> Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .carAudio }
    }
    #endif
}
