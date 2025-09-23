import PocketCastsDataModel
import Combine
import PocketCastsUtils
import UIKit
import SwiftUI

class PodcastFilterOverlayController: PodcastChooserViewController, PodcastSelectionDelegate {
    var filterToEdit: EpisodeFilter!
    var filterTintColor: UIColor!

    var selectAllSwitch: ThemeableSwitch!
    var headerView: PodcastSelectionHeaderView!
    var footerView: ThemeableView!

    let podcastFilterCellId = "PodcastFilterCell"
    let podcastsSmartRuleHeaderCellId = "PodcastsSmartRuleHeaderCellId"
    var saveButton: UIButton!

    private var cancellables = Set<AnyCancellable>()
    private var viewModel: SmartRuleToggleViewModel!
    private var switchIsOn: Bool {
        FeatureFlag.playlistsRebranding.enabled ? viewModel.toggleIsOn : selectAllSwitch.isOn
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if FeatureFlag.playlistsRebranding.enabled {
            largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        }

        insetAdjuster = InsetAdjuster(ignoreMiniPlayer: true)
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: podcastTable)

        delegate = self
        podcastTable.delegate = self
        podcastTable.dataSource = self
        podcastTable.separatorStyle = .none
        podcastTable.register(UINib(nibName: "PodcastFilterSelectionCell", bundle: nil), forCellReuseIdentifier: podcastFilterCellId)
        if FeatureFlag.playlistsRebranding.enabled {
            podcastTable.register(UITableViewCell.self, forCellReuseIdentifier: podcastsSmartRuleHeaderCellId)
        }

        setupNavBar()
        navigationController?.navigationBar.sizeToFit()
        if FeatureFlag.playlistsRebranding.enabled {
            viewModel = SmartRuleToggleViewModel(
                toggleIsOn: filterToEdit.filterAllPodcasts,
                title: L10n.playlistSmartRulePodcastsHeaderTitle,
                enabledString: L10n.playlistSmartRulePodcastsHeaderSubtitleAutoAdd,
                disabledString: L10n.playlistSmartRulePodcastsHeaderSubtitleManualAdd
            )
            viewModel.$toggleIsOn
                .dropFirst()
                .receive(on: RunLoop.main)
                .sink { [weak self] newValue in
                    self?.selectAllSwitchValueChanged()
                }
                .store(in: &cancellables)
        }
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
        if !FeatureFlag.playlistsRebranding.enabled {
            updateSwitchStatus()
        }
        updateRightBarBtn()
    }

    func setupNavBar() {
        let backgroundColor: UIColor
        if FeatureFlag.playlistsRebranding.enabled {
            backgroundColor = AppTheme.viewBackgroundColor()
            changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)
        } else {
            backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            setupCloseButton()
            changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon02))
        }
        title = L10n.filterChoosePodcasts
        navigationController?.navigationBar.prefersLargeTitles = true
        if FeatureFlag.playlistsRebranding.enabled {
            navigationItem.largeTitleDisplayMode = .always
        }

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = backgroundColor
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01),
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22, weight: .bold)
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
        if FeatureFlag.playlistsRebranding.enabled {
            return
        }
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
        if FeatureFlag.playlistsRebranding.enabled {
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
        } else {
            saveButton.backgroundColor = filterToEdit.playlistColor()
        }
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

        podcastTableBottomConstraint.isActive = false

        view.addSubview(footerView)
        view.bringSubviewToFront(footerView)
        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            footerView.heightAnchor.constraint(equalToConstant: 110),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

            podcastTable.bottomAnchor.constraint(equalTo: footerView.topAnchor)
        ])

        view.layoutSubviews()
    }

    private func setupSaveButtonTitle() {
        let title = FeatureFlag.playlistsRebranding.enabled ? L10n.playlistSmartRuleSaveButton : L10n.filterUpdate
        let attributedTitle = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
        saveButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    private func updateSaveButtonEnabledState() {
        guard FeatureFlag.playlistsRebranding.enabled else {
            saveButton.isEnabled = true
            saveButton.alpha = 1.0
            return
        }
        saveButton.alpha = selectedUuids.isEmpty ? 0.4 : 1.0
        saveButton.isEnabled = !selectedUuids.isEmpty
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

        if FeatureFlag.playlistsRebranding.enabled {
            filterToEdit.podcastSmartRuleApplied = true
        }

        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)
        if FeatureFlag.playlistsRebranding.enabled {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }

        if !filterToEdit.isNew {
            Analytics.track(.filterUpdated, properties: ["group": "podcasts", "source": analyticsSource])
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
        if switchIsOn {
            customRightBtn = nil
        } else {
            updateSelectBtn()
            customRightBtn = selectBtn
        }
        refreshRightButtons()
    }

    @objc func selectAllSwitchValueChanged() {
        selectedUuids.removeAll()
        if switchIsOn {
            for podcast in allPodcasts {
                selectedUuids.append(podcast.uuid)
            }
        }
        Analytics.track(.settingsSelectPodcastsSelectAllPodcastsToggled, properties: ["enabled": switchIsOn, "source": analyticsSource])
        if !FeatureFlag.playlistsRebranding.enabled {
            setSwitchSubtitle()
        }
        updateRightBarBtn()
        updateSaveButtonEnabledState()
        podcastTable.reloadData()
    }

    // MARK: - PodcastSelectionDelegate

    func bulkSelectionChange(selected: Bool) {
        updateRightBarBtn()
        updateSaveButtonEnabledState()
    }

    func podcastSelected(podcast: String) {
        updateRightBarBtn()
        updateSaveButtonEnabledState()
    }

    func podcastUnselected(podcast: String) {
        updateRightBarBtn()
        updateSaveButtonEnabledState()
    }

    func didChangePodcasts(numberSelected: Int) {}

    // MARK: - TableView data source and delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return FeatureFlag.playlistsRebranding.enabled ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if FeatureFlag.playlistsRebranding.enabled, section == 0 {
            return 1
        }
        return allPodcasts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if FeatureFlag.playlistsRebranding.enabled, indexPath.section == 0 {
            let cell = podcastTable.dequeueReusableCell(withIdentifier: podcastsSmartRuleHeaderCellId)!
            cell.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentView.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentConfiguration = UIHostingConfiguration {
                SmartRuleToggleHeaderView(viewModel: viewModel)
                    .environmentObject(Theme.sharedTheme)
                    .frame(maxWidth: .infinity, minHeight: 70.0, alignment: .leading)
            }
            .margins(.horizontal, 0)
            .margins(.vertical, 0)
            return cell
        }
        let cell = podcastTable.dequeueReusableCell(withIdentifier: podcastFilterCellId) as! PodcastFilterSelectionCell
        if FeatureFlag.playlistsRebranding.enabled {
            cell.setTintColor(color: AppTheme.colorForStyle(.primaryInteractive01))
        } else {
            cell.setTintColor(color: filterToEdit.playlistColor())
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if FeatureFlag.playlistsRebranding.enabled, indexPath.section == 0 {
            return
        }
        super.tableView(tableView, didSelectRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if FeatureFlag.playlistsRebranding.enabled, indexPath.section == 0 {
            return
        }
        let podcastCell = cell as! PodcastFilterSelectionCell

        let podcast = allPodcasts[indexPath.row]
        podcastCell.populateFrom(podcast)
        podcastCell.contentView.alpha = switchIsOn ? 0.3 : 1
        podcastCell.setSelected(selectedUuids.contains(podcast.uuid), animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if FeatureFlag.playlistsRebranding.enabled, indexPath.section == 0 {
            return UITableView.automaticDimension
        }
        return 72
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if FeatureFlag.playlistsRebranding.enabled, indexPath.section == 0 {
            return false
        }
        if switchIsOn {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if FeatureFlag.playlistsRebranding.enabled, indexPath.section == 0 {
            return nil
        }
        if switchIsOn {
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
