import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class PodcastFilterOverlayController: PodcastChooserViewController, PodcastSelectionDelegate {
    var filterToEdit: EpisodeFilter!
    var filterTintColor: UIColor!

    var selectAllSwitch: ThemeableSwitch!
    var headerView: PodcastSelectionHeaderView!
    var footerView: ThemeableView!

    let podcastFilterCellId = "PodcastFilterCell"
    var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        podcastTable.delegate = self
        podcastTable.dataSource = self
        podcastTable.separatorStyle = .none
        podcastTable.register(UINib(nibName: "PodcastFilterSelectionCell", bundle: nil), forCellReuseIdentifier: podcastFilterCellId)

        setupNavBar()
        navigationController?.navigationBar.sizeToFit()
        setupHeader()
        setupSaveButton()

        if filterToEdit.filterAllPodcasts {
            for podcast in allPodcasts {
                selectedUuids.append(podcast.uuid)
            }
        } else {
            let allPodcastUuids = allPodcasts.map(\.uuid)
            selectedUuids = filterToEdit.podcastUuids.components(separatedBy: ",").compactMap { allPodcastUuids.contains($0) ? $0 : nil }
        }
        updateSwitchStatus()
        updateRightBarBtn()
    }

    func setupNavBar() {
        setupCloseButton()
        changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon02))
        title = L10n.filterChoosePodcasts
        navigationController?.navigationBar.prefersLargeTitles = true

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
    }

    func setupCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    func setupHeader() {
        headerView = PodcastSelectionHeaderView()
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        headerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        headerView.layoutIfNeeded()
        podcastTable.tableHeaderView = headerView
        selectAllSwitch = headerView.selectAllSwitch
        selectAllSwitch.setOn(filterToEdit.filterAllPodcasts, animated: true)
        selectAllSwitch.addTarget(self, action: #selector(selectAllSwitchValueChanged), for: .valueChanged)
        selectAllSwitch.onTintColor = filterToEdit.playlistColor()
    }

    func setupSaveButton() {
        footerView = ThemeableView()
        footerView.backgroundColor = AppTheme.viewBackgroundColor()
        saveButton = UIButton(type: .custom)
        saveButton.backgroundColor = filterToEdit.playlistColor()
        setupSaveButtonTitle()
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveTapped(sender:)), for: .touchUpInside)
        footerView.addSubview(saveButton)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -34),
            saveButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16)
        ])

        view.addSubview(footerView)
        view.bringSubviewToFront(footerView)
        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            footerView.heightAnchor.constraint(equalToConstant: 110),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

        view.layoutSubviews()
    }

    private func setupSaveButtonTitle() {
        let attributedTitle = NSAttributedString(string: L10n.filterUpdate, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
        saveButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func saveTapped(sender: Any) {
        if selectedUuids.count == allPodcasts.count || selectedUuids.count == 0 {
            filterToEdit.podcastUuids = ""
            filterToEdit.filterAllPodcasts = true
        } else {
            filterToEdit.podcastUuids = selectedUuids.joined(separator: ",")
            filterToEdit.filterAllPodcasts = false
        }

        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(filter: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: filterToEdit)
        dismiss(animated: true, completion: nil)

        if !filterToEdit.isNew {
            Analytics.track(.filterUpdated, properties: ["group": "podcasts", "source": "filters"])
        }
    }

    func updateSwitchStatus() {
        let allSelected = selectedUuids.count == allPodcasts.count
        selectAllSwitch.setOn(allSelected, animated: true)
        setSwitchSubtitle()
    }

    func setSwitchSubtitle() {
        let allSelected = selectedUuids.count == allPodcasts.count
        if allSelected {
            headerView.subtitleLabel.text = FeatureFlag.useFollowNaming.enabled ? L10n.filterAutoAddSubtitleNew : L10n.filterAutoAddSubtitle
        } else {
            headerView.subtitleLabel.text = FeatureFlag.useFollowNaming.enabled ? L10n.filterManualAddSubtitleNew : L10n.filterManualAddSubtitle
        }
    }

    func updateRightBarBtn() {
        if selectAllSwitch.isOn {
            customRightBtn = nil
        } else {
            updateSelectBtn()
            customRightBtn = selectBtn
        }
        refreshRightButtons()
    }

    @objc func selectAllSwitchValueChanged() {
        selectedUuids.removeAll()
        if selectAllSwitch.isOn {
            for podcast in allPodcasts {
                selectedUuids.append(podcast.uuid)
            }
        }
        setSwitchSubtitle()
        updateRightBarBtn()
        podcastTable.reloadData()
    }

    // MARK: - PodcastSelectionDelegate

    func bulkSelectionChange(selected: Bool) {
        updateRightBarBtn()
    }

    func podcastSelected(podcast: String) {
        updateRightBarBtn()
    }

    func podcastUnselected(podcast: String) {
        updateRightBarBtn()
    }

    func didChangePodcasts() {}

    // MARK: - TableView data source and delegate

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = podcastTable.dequeueReusableCell(withIdentifier: podcastFilterCellId) as! PodcastFilterSelectionCell
        cell.setTintColor(color: filterToEdit.playlistColor())
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let podcastCell = cell as! PodcastFilterSelectionCell

        let podcast = allPodcasts[indexPath.row]
        podcastCell.populateFrom(podcast)
        podcastCell.contentView.alpha = selectAllSwitch.isOn ? 0.3 : 1
        podcastCell.setSelected(selectedUuids.contains(podcast.uuid), animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if selectAllSwitch.isOn {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if selectAllSwitch.isOn {
            return nil
        }
        return indexPath
    }

    override func handleThemeChanged() {
        super.handleThemeChanged()
        footerView.backgroundColor = AppTheme.viewBackgroundColor()
        saveButton.backgroundColor = filterToEdit.playlistColor()
        selectAllSwitch.onTintColor = filterToEdit.playlistColor()
        podcastTable.reloadData()
        setupNavBar()
        setupSaveButtonTitle()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
