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

    private var keyBoardHeight: CGFloat = .zero
    private var tempPodcasts: [Podcast] = []
    private var isSearching = false
    private var searchController: PCSearchBarController?
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: SmartRuleToggleViewModel!
    private let playlistsRebrandingEnabled = FeatureFlag.playlistsRebranding.enabled
    private var switchIsOn: Bool {
        playlistsRebrandingEnabled ? viewModel.toggleIsOn : selectAllSwitch.isOn
    }
    private lazy var searchBar: UIView? = {
        let view = UIView()
        view.backgroundColor = .clear

        searchController = PCSearchBarController()
        searchController?.searchDebounce = 0.2

        guard let searchController else {
            return nil
        }

        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            searchController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        searchController.placeholderText = L10n.search
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if playlistsRebrandingEnabled {
            largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        }

        insetAdjuster = InsetAdjuster(ignoreMiniPlayer: true)
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: podcastTable)

        delegate = self
        podcastTable.delegate = self
        podcastTable.dataSource = self
        podcastTable.separatorStyle = .none
        podcastTable.register(UINib(nibName: "PodcastFilterSelectionCell", bundle: nil), forCellReuseIdentifier: podcastFilterCellId)
        podcastTable.estimatedRowHeight = UITableView.automaticDimension
        if playlistsRebrandingEnabled {
            podcastTable.register(UITableViewCell.self, forCellReuseIdentifier: podcastsSmartRuleHeaderCellId)
            podcastTable.register(EmptyStateCell.self, forCellReuseIdentifier: EmptyStateCell.reuseIdentifier)
            podcastTable.backgroundColor = AppTheme.viewBackgroundColor()
            addCustomObserver(UIResponder.keyboardWillShowNotification, selector: #selector(keyboardWillShow(_:)))
            addCustomObserver(UIResponder.keyboardWillHideNotification, selector: #selector(keyboardWillHide(_:)))
        }
        podcastTable.sectionHeaderTopPadding = 0

        setupNavBar()
        navigationController?.navigationBar.sizeToFit()
        if playlistsRebrandingEnabled {
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
        if !playlistsRebrandingEnabled {
            updateSwitchStatus()
        }
        updateRightBarBtn()
    }

    func setupNavBar() {
        let backgroundColor: UIColor
        if playlistsRebrandingEnabled {
            backgroundColor = AppTheme.viewBackgroundColor()
            changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)
            title = L10n.filterChoosePodcasts.sentenceCased
        } else {
            backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            setupCloseButton()
            changeNavTint(titleColor: nil, iconsColor: AppTheme.colorForStyle(.primaryIcon02))
            title = L10n.filterChoosePodcasts
        }
        navigationController?.navigationBar.prefersLargeTitles = true
        if playlistsRebrandingEnabled {
            navigationItem.largeTitleDisplayMode = .always
        }

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = backgroundColor
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01),
            NSAttributedString.Key.font: UIFont.font(ofSize: 22, weight: .bold, scalingWith: .title2)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
    }

    func setupCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        navigationItem.leftBarButtonItem = closeButton
    }

    func setupHeader() {
        if playlistsRebrandingEnabled {
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
        if playlistsRebrandingEnabled {
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
        let title = playlistsRebrandingEnabled ? L10n.playlistSmartRuleSaveButton : L10n.filterUpdate

        saveButton.setTitle(title, for: .normal)
        saveButton.titleLabel?.font = UIFont.font(ofSize: 18.0, weight: .semibold, scalingWith: .headline)
        saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
        saveButton.titleLabel?.numberOfLines = 0
        saveButton.titleLabel?.textAlignment = .center
        saveButton.tintColor = ThemeColor.primaryInteractive02()
        saveButton.titleLabel?.lineBreakMode = .byWordWrapping
        if let label = saveButton.titleLabel {
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(
                    equalTo: saveButton.topAnchor, constant: 8
                ),
                label.bottomAnchor.constraint(
                    equalTo: saveButton.bottomAnchor, constant: -8
                ),
                label.leadingAnchor.constraint(
                    equalTo: saveButton.leadingAnchor, constant: 8
                ),
                label.trailingAnchor.constraint(
                    equalTo: saveButton.trailingAnchor, constant: -8
                ),
            ])
        }
    }

    private func updateSaveButtonEnabledState() {
        guard playlistsRebrandingEnabled else {
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
        let podcasts = currentPodcastsSource()
        if selectedUuids.count == podcasts.count || selectedUuids.count == 0 {
            filterToEdit.podcastUuids = ""
            filterToEdit.filterAllPodcasts = true
        } else {
            filterToEdit.podcastUuids = selectedUuids.joined(separator: ",")
            filterToEdit.filterAllPodcasts = false
        }

        if playlistsRebrandingEnabled {
            filterToEdit.podcastSmartRuleApplied = true
        }

        filterToEdit.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filterToEdit)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filterToEdit)
        if playlistsRebrandingEnabled {
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
            if playlistsRebrandingEnabled, isSearching {
                for podcast in tempPodcasts {
                    selectedUuids.append(podcast.uuid)
                }
            } else {
                for podcast in allPodcasts {
                    selectedUuids.append(podcast.uuid)
                }
            }
        }
        Analytics.track(.settingsSelectPodcastsSelectAllPodcastsToggled, properties: ["enabled": switchIsOn, "source": analyticsSource])
        if !playlistsRebrandingEnabled {
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

    override func currentPodcastsSource() -> [Podcast] {
        if playlistsRebrandingEnabled {
            return isSearching ? tempPodcasts : allPodcasts
        }
        return allPodcasts
    }

    // MARK: - TableView data source and delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return playlistsRebrandingEnabled ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlistsRebrandingEnabled {
            switch section {
            case 0:
                return 1
            default:
                return allPodcasts.isEmpty ? 1 : allPodcasts.count
            }
        }
        return allPodcasts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if playlistsRebrandingEnabled {
            if indexPath.section == 0 {
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
            } else if allPodcasts.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: EmptyStateCell.reuseIdentifier,
                    for: indexPath
                ) as! EmptyStateCell
                cell.configure(
                    title: L10n.discoverNoPodcastsFound,
                    message: L10n.discoverNoPodcastsFoundMsg,
                    icon: {
                        Image(systemName: "info.circle")
                    }
                )
                return cell
            }
        }
        let podcastCell = podcastTable.dequeueReusableCell(withIdentifier: podcastFilterCellId) as! PodcastFilterSelectionCell
        if playlistsRebrandingEnabled {
            podcastCell.setTintColor(color: AppTheme.colorForStyle(.primaryInteractive01))
        } else {
            podcastCell.setTintColor(color: filterToEdit.playlistColor())
        }
        let podcast = allPodcasts[indexPath.row]
        podcastCell.populateFrom(podcast)
        podcastCell.contentView.alpha = switchIsOn ? 0.3 : 1
        podcastCell.setSelected(selectedUuids.contains(podcast.uuid), animated: true)
        return podcastCell
    }

     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if playlistsRebrandingEnabled {
            if indexPath.section == 0 || (indexPath.section == 1 && allPodcasts.isEmpty) {
                return
            }
        }
        super.tableView(tableView, didSelectRowAt: indexPath)
    }

     func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if playlistsRebrandingEnabled {
            if indexPath.section == 0 || (indexPath.section == 1 && allPodcasts.isEmpty) {
                return
            }
        }
        let podcastCell = cell as! PodcastFilterSelectionCell

        let podcast = allPodcasts[indexPath.row]
        podcastCell.populateFrom(podcast)
        podcastCell.contentView.alpha = switchIsOn ? 0.3 : 1
        podcastCell.setSelected(selectedUuids.contains(podcast.uuid), animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if playlistsRebrandingEnabled {
            if indexPath.section == 0 || (indexPath.section == 1 && allPodcasts.isEmpty) {
                return UITableView.automaticDimension
            }
            return UITableView.automaticDimension
        }
        return 72
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if playlistsRebrandingEnabled {
            if indexPath.section == 0 || (indexPath.section == 1 && allPodcasts.isEmpty) {
                return false
            }
        }
        if switchIsOn {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if playlistsRebrandingEnabled {
            if indexPath.section == 0 || (indexPath.section == 1 && allPodcasts.isEmpty) {
                return nil
            }
        }
        if switchIsOn {
            return nil
        }
        return indexPath
    }

    override func handleThemeChanged() {
        super.handleThemeChanged()
        footerView.backgroundColor = AppTheme.viewBackgroundColor()
        if playlistsRebrandingEnabled {
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
        } else {
            saveButton.backgroundColor = filterToEdit.playlistColor()
            selectAllSwitch.onTintColor = filterToEdit.playlistColor()
        }
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard playlistsRebrandingEnabled else {
            return
        }

        let keyBoardHeight = isSearching ? keyBoardHeight - 110 : 0
        podcastTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyBoardHeight, right: 0)
        podcastTable.verticalScrollIndicatorInsets = podcastTable.contentInset
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        adjustTextViewForKeyboard(notification: notification, show: true)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        adjustTextViewForKeyboard(notification: notification, show: false)
    }

    private func adjustTextViewForKeyboard(notification: Notification, show: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        keyBoardHeight = (show ? keyboardHeight - (view.distanceFromBottom() ?? 0) : 0)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}

extension PodcastFilterOverlayController: PCSearchBarDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if playlistsRebrandingEnabled, section == 1 {
            return searchBar
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if playlistsRebrandingEnabled, section == 1 {
            return PCSearchBarController.defaultHeight
        }
        return .leastNormalMagnitude
    }

    func searchDidBegin() {
        if isSearching {
            return
        }
        isSearching = true
        tempPodcasts = allPodcasts
    }

    func searchDidEnd() {
        isSearching = false
        allPodcasts = tempPodcasts
        podcastTable.reloadData()
        tempPodcasts.removeAll()
    }

    func searchWasCleared() {
        allPodcasts = tempPodcasts
        podcastTable.reloadData()
    }

    func searchTermChanged(_ searchTerm: String) { }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        allPodcasts = tempPodcasts.filter {
            guard let title = $0.title else {
                return false
            }
            return title.localizedCaseInsensitiveContains(searchTerm)
        }

        podcastTable.reloadData()

        completion()
    }
}
