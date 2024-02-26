import PocketCastsDataModel
import PocketCastsServer
import UIKit

class AutoAddToUpNextViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let disclosureCellId = "DisclosureCell"
    private let podcastDisclosureCellId = "PodcastDisclosureCell"

    private var autoDownloadPodcasts = [Podcast]()

    private enum TableRow { case autoAddLimit, ifLimitReached, selectPodcasts }
    private let topSettingsData: [TableRow] = [.autoAddLimit, .ifLimitReached, .selectPodcasts]

    @IBOutlet var mainTable: UITableView! {
        didSet {
            mainTable.register(UINib(nibName: "DisclosureCell", bundle: nil), forCellReuseIdentifier: disclosureCellId)
            mainTable.register(UINib(nibName: "PodcastDisclosureCell", bundle: nil), forCellReuseIdentifier: podcastDisclosureCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsAutoAdd
        reloadDownloadedPodcasts()

        Analytics.track(.settingsAutoAddUpNextShown)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? topSettingsData.count : autoDownloadPodcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let row = topSettingsData[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: disclosureCellId, for: indexPath) as! DisclosureCell
            switch row {
            case .autoAddLimit:
                cell.cellLabel.text = L10n.settingsAutoAddLimit
                cell.cellSecondaryLabel.text = ServerSettings.autoAddToUpNextLimit().localized()
            case .ifLimitReached:
                cell.cellLabel.text = L10n.settingsAutoAddLimitReached

                let limitAction = ServerSettings.onAutoAddLimitReached()
                cell.cellSecondaryLabel.text = limitAction.description(short: true)
            case .selectPodcasts:
                let podcastCount = autoDownloadPodcasts.count
                cell.cellLabel.text = podcastCount == 1 ? L10n.chosenPodcastsSingular : L10n.chosenPodcastsPluralFormat(podcastCount.localized())
                cell.cellSecondaryLabel.text = nil
            }

            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: podcastDisclosureCellId, for: indexPath) as! PodcastDisclosureCell
        let podcast = autoDownloadPodcasts[indexPath.row]
        let autoDownloadSetting = podcast.autoAddToUpNextSetting() ?? .addLast
        cell.populate(from: podcast, secondaryText: autoDownloadSetting.description)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            let row = topSettingsData[indexPath.row]
            switch row {
            case .autoAddLimit:
                let options = OptionsPicker(title: L10n.settingsAutoAddLimit)
                addAutoAddLimit(amount: 10, to: options)
                addAutoAddLimit(amount: 20, to: options)
                addAutoAddLimit(amount: 50, to: options)
                addAutoAddLimit(amount: 100, to: options)
                addAutoAddLimit(amount: 200, to: options)
                addAutoAddLimit(amount: 500, to: options)
                addAutoAddLimit(amount: 1000, to: options)

                options.show(statusBarStyle: preferredStatusBarStyle)
            case .ifLimitReached:
                let options = OptionsPicker(title: L10n.settingsAutoAddLimitReached)
                addOnLimitReached(action: .addToTopOnly, to: options)
                addOnLimitReached(action: .stopAdding, to: options)

                options.show(statusBarStyle: preferredStatusBarStyle)
            case .selectPodcasts:
                let podcastSelectViewController = PodcastChooserViewController()
                podcastSelectViewController.delegate = self
                let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
                podcastSelectViewController.selectedUuids = allPodcasts.filter { $0.autoAddToUpNextOn() }.map(\.uuid)
                navigationController?.pushViewController(podcastSelectViewController, animated: true)
            }
        } else {
            let podcast = autoDownloadPodcasts[indexPath.row]
            let options = OptionsPicker(title: L10n.autoAdd)
            addActionForPodcast(podcast: podcast, setting: .addFirst, label: L10n.top, to: options)
            addActionForPodcast(podcast: podcast, setting: .addLast, label: L10n.bottom, to: options)

            options.show(statusBarStyle: preferredStatusBarStyle)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 54 : 72
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 54 : 72
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? nil : L10n.settingsAutoAddPodcasts
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let autoAddLimit = ServerSettings.autoAddToUpNextLimit()
        let onLimitReached = ServerSettings.onAutoAddLimitReached()
        let explanationStr: String
        if onLimitReached == .addToTopOnly {
            explanationStr = L10n.settingsAutoAddLimitSubtitleTop(autoAddLimit.localized())
        } else {
            explanationStr = L10n.settingsAutoAddLimitSubtitleStop(autoAddLimit.localized())
        }

        return section == 0 ? explanationStr : nil
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        ThemeableTable.setHeaderFooterTextColor(on: view)
    }

    func reloadDownloadedPodcasts() {
        autoDownloadPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false).filter { $0.autoAddToUpNextOn() }
    }

    private func addActionForPodcast(podcast: Podcast, setting: AutoAddToUpNextSetting, label: String, to: OptionsPicker) {
        let action = OptionAction(label: label, selected: podcast.autoAddToUpNextSetting() == setting) { [weak self] in
            podcast.setAutoAddToUpNext(setting: setting)
            DataManager.sharedManager.save(podcast: podcast)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
            self?.mainTable.reloadData()
            Settings.trackValueChanged(.settingsAutoAddUpNextPodcastPositionOptionChanged, value: setting)
        }
        to.addAction(action: action)
    }

    private func addOnLimitReached(action: AutoAddLimitReachedAction, to: OptionsPicker) {
        let selectedSetting = ServerSettings.onAutoAddLimitReached()
        let action = OptionAction(label: action.description(short: false), selected: selectedSetting == action) { [weak self] in
            ServerSettings.setOnAutoAddLimitReached(action: action)
            self?.mainTable.reloadData()

            Settings.trackValueChanged(.settingsAutoAddUpNextLimitReachedChanged, value: action)
        }
        to.addAction(action: action)
    }

    private func addAutoAddLimit(amount: Int, to: OptionsPicker) {
        let selectedSetting = ServerSettings.autoAddToUpNextLimit()
        let action = OptionAction(label: L10n.episodeCountPluralFormat(amount.localized()).localizedCapitalized, selected: selectedSetting == amount) { [weak self] in
            ServerSettings.setAutoAddToUpNextLimit(amount)
            self?.mainTable.reloadData()

            Settings.trackValueChanged(.settingsAutoAddUpNextAutoAddLimitChanged, value: amount)
        }
        to.addAction(action: action)
    }
}
