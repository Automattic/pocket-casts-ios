import Foundation

extension CastToViewController: UITableViewDelegate, UITableViewDataSource {
    private static let castCellId = "GoogleCastCell"

    func setupTable() {
        castTable.register(UINib(nibName: "GoogleCastCell", bundle: nil), forCellReuseIdentifier: CastToViewController.castCellId)
        castTable.tableFooterView = UIView(frame: .zero)
        castTable.themeOverride = themeOverride
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CastToViewController.castCellId, for: indexPath) as! GoogleCastCell

        let device = devices[indexPath.row]
        if device.type == .TV {
            cell.deviceIcon.image = UIImage(named: "chromecast-video")
        } else {
            cell.deviceIcon.image = UIImage(named: "chromecast-audio")
        }
        cell.themeOverride = themeOverride
        cell.deviceIcon.tintColor = ThemeColor.primaryIcon01(for: themeOverride)
        cell.deviceName.text = device.friendlyName
        cell.deviceName.themeOverride = themeOverride

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        GoogleCastManager.sharedManager.connectToDevice(device)

        Analytics.track(.chromecastStartedCasting)
        AnalyticsPlaybackHelper.shared.currentSource = analyticsSource

        dismiss(animated: true, completion: nil)
    }
}
