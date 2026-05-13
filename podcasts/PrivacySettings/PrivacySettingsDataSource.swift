import PocketCastsUtils
import UIKit

class PrivacySettingsDataSource: NSObject, UITableViewDataSource {
    private let switchCellId = "SwitchCell"
    private let themeableCellId = "ThemeableCell"
    private let themeableCellWithoutSelectionId = "ThemeableCellWithoutSelectionId"

    private enum Section: Int, CaseIterable {
        case profileSharing
        case analytics
    }

    func registerCells(for tableView: UITableView) {
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: switchCellId)
        tableView.register(ThemeableCell.self, forCellReuseIdentifier: themeableCellId)
        tableView.register(ThemeableCellWithoutSelection.self, forCellReuseIdentifier: themeableCellWithoutSelectionId)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        guard FeatureFlag.shareProfile.enabled else { return 1 }
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let resolvedSection = resolvedSection(for: section)
        switch resolvedSection {
        case .profileSharing:
            return 4
        case .analytics:
            return 4
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resolvedSection = resolvedSection(for: indexPath.section)
        switch resolvedSection {
        case .profileSharing:
            return profileSharingCell(for: tableView, row: indexPath.row)
        case .analytics:
            return analyticsCell(for: tableView, row: indexPath.row)
        }
    }

    // MARK: - Profile Sharing Section

    private func profileSharingCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId) as! SwitchCell
            cell.cellLabel.text = L10n.shareProfileFollowedPodcasts
            cell.cellSwitch.isOn = UserDefaults.standard.object(forKey: ShareProfileViewModel.followedPodcastsKey) as? Bool ?? true
            cell.cellSwitch.removeTarget(self, action: nil, for: .valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(followedPodcastsToggled(_:)), for: .valueChanged)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId) as! SwitchCell
            cell.cellLabel.text = L10n.shareProfileRecentEpisodes
            cell.cellSwitch.isOn = UserDefaults.standard.object(forKey: ShareProfileViewModel.recentEpisodesKey) as? Bool ?? true
            cell.cellSwitch.removeTarget(self, action: nil, for: .valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(recentEpisodesToggled(_:)), for: .valueChanged)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId) as! SwitchCell
            cell.cellLabel.text = L10n.shareProfilePlaylists
            cell.cellSwitch.isOn = UserDefaults.standard.object(forKey: ShareProfileViewModel.playlistsKey) as? Bool ?? true
            cell.cellSwitch.removeTarget(self, action: nil, for: .valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(playlistsToggled(_:)), for: .valueChanged)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellWithoutSelectionId) as! ThemeableCellWithoutSelection
            cell.style = .primaryUi02
            cell.textLabel?.textColor = ThemeColor.primaryText02()
            cell.textLabel?.text = L10n.shareProfilePrivacySettingsFooter
            configureDynamicTypeCell(cell)
            return cell
        }
    }

    @objc private func followedPodcastsToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: ShareProfileViewModel.followedPodcastsKey)
    }

    @objc private func recentEpisodesToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: ShareProfileViewModel.recentEpisodesKey)
    }

    @objc private func playlistsToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: ShareProfileViewModel.playlistsKey)
    }

    // MARK: - Analytics Section

    private func analyticsCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellWithoutSelectionId) as! ThemeableCellWithoutSelection
            cell.style = .primaryUi02
            cell.textLabel?.textColor = ThemeColor.primaryText02()
            cell.textLabel?.text = L10n.settingsCollectInformationAdditionalInformation
            configureDynamicTypeCell(cell)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellId) as! SwitchCell
            cell.cellLabel.text = L10n.settingsFirstPartyAnalytics
            cell.cellSwitch.isOn = !Settings.analyticsOptOut()
            cell.cellSwitch.removeTarget(self, action: nil, for: UIControl.Event.valueChanged)
            cell.cellSwitch.addTarget(self, action: #selector(pushToggled(_:)), for: UIControl.Event.valueChanged)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellWithoutSelectionId) as! ThemeableCellWithoutSelection
            cell.style = .primaryUi02
            cell.imageView?.image = UIImage()
            cell.textLabel?.textColor = ThemeColor.primaryText02()
            cell.textLabel?.text = L10n.settingsAllowCollectionFirstParty
            configureDynamicTypeCell(cell)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: themeableCellId) as! ThemeableCell
            cell.textLabel?.textColor = ThemeColor.primaryInteractive01()
            cell.textLabel?.text = L10n.settingsReadPrivacyPolicy
            configureDynamicTypeCell(cell)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let resolvedSection = resolvedSection(for: section)
        switch resolvedSection {
        case .profileSharing:
            return L10n.shareProfileProfileSharing
        case .analytics:
            return L10n.settingsAnalytics
        }
    }

    // MARK: - Helpers

    private func resolvedSection(for section: Int) -> Section {
        guard FeatureFlag.shareProfile.enabled else { return .analytics }
        return Section(rawValue: section) ?? .analytics
    }

    private func configureDynamicTypeCell(_ cell: ThemeableCell) {
        cell.textLabel?.font = .font(with: .callout)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
    }

    @objc private func pushToggled(_ sender: UISwitch) {
        if sender.isOn {
            Analytics.shared.optInOfAnalytics()
        } else {
            Analytics.shared.optOutOfAnalytics()
        }
    }
}

private class ThemeableCellWithoutSelection: ThemeableCell {
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
}
