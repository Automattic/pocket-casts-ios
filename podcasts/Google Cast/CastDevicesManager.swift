import Foundation
import GoogleCast

class CastDevicesManager: NSObject, GCKDiscoveryManagerListener {
    // MARK: - GCKDiscoveryManagerListener

    private var devices = [GCKDevice]()

    func didUpdateDeviceList() {
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager

        let deviceCount = discoveryManager.deviceCount

        devices.removeAll()
        for index in 0 ..< deviceCount {
            if let device = discoveryManager.device(at: index) as GCKDevice? {
                devices.append(device)
            }
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.googleCastStatusChanged)
    }

    func availableDevices() -> [GCKDevice] {
        devices
    }
}
