import GoogleCast
import UIKit

class CastDeviceVolumeView: UIStackView {
    private var devices: [GCKMultizoneDevice]?
    var themeOverride: Theme.ThemeType?

    func update() {
        removeAllSubviews()

        devices = GoogleCastManager.sharedManager.allMultiZoneDevices()

        // there's no point in controlling multi-room audio that only has 1 speaker, so check for that here
        guard let devices = devices, devices.count > 1 else { return }

        for (index, device) in devices.enumerated() {
            addDevice(device, index: index)
        }
    }

    private var sliderColor = ThemeColor.primaryInteractive01()
    func updateTrackColor(_ color: UIColor) {
        sliderColor = color
        update()
    }

    private func addDevice(_ device: GCKMultizoneDevice, index: Int) {
        let topDivider = ThemeDividerView()
        topDivider.themeOverride = themeOverride
        addArrangedSubview(topDivider)
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        topDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let padding = UIView()
        padding.backgroundColor = UIColor.clear
        addArrangedSubview(padding)
        padding.translatesAutoresizingMaskIntoConstraints = false
        padding.heightAnchor.constraint(equalToConstant: 4).isActive = true

        let label = ThemeableLabel()
        label.themeOverride = themeOverride
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 15)
        label.text = device.friendlyName ?? L10n.chromecastUnnamedDevice
        addArrangedSubview(label)

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.tag = index
        slider.value = device.volumeLevel
        slider.tintColor = sliderColor
        slider.minimumTrackTintColor = sliderColor
        slider.minimumValueImage = UIImage(named: "chromecast-volume")
        addArrangedSubview(slider)

        slider.addTarget(self, action: #selector(volumeSliderDidChange(_:)), for: .valueChanged)
    }

    @objc private func volumeSliderDidChange(_ sender: UISlider) {
        guard let device = devices?[safe: sender.tag] else { return }

        GoogleCastManager.sharedManager.changeDeviceVolume(device: device, volume: sender.value)
    }
}
