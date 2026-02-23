import UIKit
import SwiftUI
import PocketCastsDataModel

class NewPlaylistViewController: PCViewController {
    enum CreationType: Equatable {
        case `default`
        case addEpisode(episode: Episode)
        case addEpisodes(episodes: [Episode])

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.default, .default):
                return true
            case (.addEpisode(let lhsEpisode), .addEpisode(let rhsEpisode)):
                return lhsEpisode.uuid == rhsEpisode.uuid
            case (.addEpisodes(let lhsEpisodes), .addEpisodes(let rhsEpisodes)):
                return lhsEpisodes.map(\.uuid) == rhsEpisodes.map(\.uuid)
            default:
                return false
            }
        }
    }

    private let creationType: CreationType
    private let analyticsSource: String?

    private var creationView: UIView?
    private var smartPlaylistsTip: UIViewController? = nil

    weak var delegate: FilterCreatedDelegate?

    private var playlistName: String = ""
    private var playlistNameTextField: ThemeableTextField! {
        didSet {
            playlistNameTextField.translatesAutoresizingMaskIntoConstraints = false
            playlistNameTextField.placeholder = L10n.playlistsDefaultNewPlaylist
            playlistNameTextField.text = L10n.playlistsDefaultNewPlaylist
            playlistNameTextField.placeholderStyle = .primaryText01
            playlistNameTextField.delegate = self
            playlistNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
            playlistNameTextField.clearsOnBeginEditing = false
            playlistNameTextField.clearButtonMode = .whileEditing
            playlistNameTextField.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
            playlistNameTextField.font = .font(ofSize: 15, weight: .medium, scalingWith: .subheadline)
            playlistNameTextField.adjustsFontForContentSizeCategory = true
            playlistNameTextField.tintColor = AppTheme.colorForStyle(.primaryField03)

            if let clearButton = playlistNameTextField.value(forKey: "clearButton") as? UIButton,
               let image = clearButton.image(for: .normal) {
                let tintedImage = image.withRenderingMode(.alwaysTemplate)
                clearButton.setImage(tintedImage, for: .normal)
                clearButton.tintColor = AppTheme.colorForStyle(.primaryField03)
            }
        }
    }

    private var textFieldBorderView: UIView! {
        didSet {
            textFieldBorderView.translatesAutoresizingMaskIntoConstraints = false
            textFieldBorderView.layer.borderWidth = 2
            textFieldBorderView.layer.cornerRadius = 6
            textFieldBorderView.layer.borderColor = AppTheme.colorForStyle(.primaryField03).cgColor
        }
    }

    private var saveButton: UIButton! {
        didSet {
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.backgroundColor = AppTheme.colorForStyle(.primaryInteractive01)
            saveButton.setTitle(L10n.playlistCreationCreatePlaylistButton, for: .normal)
            saveButton.tintColor = ThemeColor.primaryInteractive02()
            saveButton.titleLabel?.font = .font(ofSize: 18.0, weight: .semibold, scalingWith: .headline)
            saveButton.layer.cornerRadius = 12
            saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
            saveButton.titleLabel?.numberOfLines = 0
            saveButton.titleLabel?.textAlignment = .center
            saveButton.addTarget(self, action: #selector(createManualPlaylist), for: .touchUpInside)
        }
    }

    init(creationType: CreationType = .default, analyticsSource: String? = nil) {
        self.creationType = creationType
        self.analyticsSource = analyticsSource
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        if creationType == .default {
            addCloseButton()
        }
        setupContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Analytics.track(.filterCreateShown)

        showSmartPlaylistTooltip()

        playlistNameTextField.becomeFirstResponder()
        playlistNameTextField.selectAll(nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            Analytics.track(.filterCreateCancelled)
        }
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        title = L10n.playlistsDefaultNewPlaylist

        largeTitleFont = UIFont.font(ofSize: 22, weight: .bold, scalingWith: .title2)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = backgroundColor
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppTheme.colorForStyle(.primaryText01)
        ]
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.sizeToFit()
    }

    private func setupContent() {
        isModalInPresentation = true

        view.backgroundColor = AppTheme.viewBackgroundColor()

        textFieldBorderView = ThemeableSelectionView()
        view.addSubview(textFieldBorderView)

        playlistNameTextField = ThemeableTextField()
        view.addSubview(playlistNameTextField)

        saveButton = UIButton(type: .custom)
        view.addSubview(saveButton)

        var constraints = [
            textFieldBorderView.topAnchor.constraint(equalTo: playlistNameTextField.topAnchor, constant: -8.0),
            textFieldBorderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            textFieldBorderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            textFieldBorderView.bottomAnchor.constraint(equalTo: playlistNameTextField.bottomAnchor, constant: 8),
            textFieldBorderView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            playlistNameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            playlistNameTextField.leadingAnchor.constraint(equalTo: textFieldBorderView.leadingAnchor, constant: 16.0),
            playlistNameTextField.trailingAnchor.constraint(equalTo: textFieldBorderView.trailingAnchor, constant: -16.0),

            saveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ]

        if creationType == .default {
            let creationViewUI = SmartPlaylistCreationView() { [weak self] in
                self?.createSmartPlaylist()
            }
            let themedVC = ThemedHostingController(rootView: creationViewUI)
            themedVC.sizingOptions = [.intrinsicContentSize, .preferredContentSize]
            self.addChild(themedVC)
            let creationView = themedVC.view!
            creationView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(creationView, belowSubview: saveButton)
            themedVC.didMove(toParent: self)
            self.creationView = creationView

            constraints.append(contentsOf: [
                creationView.topAnchor.constraint(equalTo: playlistNameTextField.bottomAnchor, constant: 16.0),
                creationView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
                creationView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
                creationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 59.0),
                saveButton.topAnchor.constraint(equalTo: creationView.bottomAnchor, constant: 24)
            ])
        } else {
            constraints.append(contentsOf: [
                saveButton.topAnchor.constraint(equalTo: playlistNameTextField.bottomAnchor, constant: 24)
            ])
        }

        NSLayoutConstraint.activate(constraints)

        view.layoutSubviews()
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func createManualPlaylist() {
        delegate?.presentingPlaylistDetail = true

        DataManager.sharedManager.bumpSortPositionForAllPlaylists()

        let playlistName = self.playlistName.isEmpty ? L10n.playlistsDefaultNewPlaylist : self.playlistName
        let playlist = PlaylistManager.createNewPlaylist()
        let firstSortPosition = max(0, DataManager.sharedManager.firstSortPositionForPlaylist() - 1)
        playlist.sortPosition = Int32(firstSortPosition)
        playlist.setTitle(playlistName, defaultTitle: L10n.playlistsDefaultNewPlaylist.localizedCapitalized)
        playlist.manual = true
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        playlist.isNew = false
        playlist.sortType = PlaylistSort.dragAndDrop.rawValue
        DataManager.sharedManager.save(playlist: playlist)
        if creationType == .default {
            UserDefaults.standard.set(playlist.uuid, forKey: Constants.UserDefaults.lastFilterShown)
            delegate?.filterCreated(newFilter: playlist)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: playlist)
        } else if case let .addEpisode(episode) = creationType {
            let didAdd = DataManager.sharedManager.add(episodes: [episode], to: playlist)
            guard didAdd else {
                let theme: any ToastTheme = ToastIconTheme(iconName: "option-alert", iconColor: Theme.sharedTheme.primaryIcon01)
                Toast.show(L10n.playlistManualCreateErrorMessage, theme: theme)
                return
            }

            Analytics.track(.addToPlaylistsCreateNewPlaylistTapped, properties: ["source": analyticsSource ?? "unknown"])

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: playlist)

            Analytics.track(.filterCreated)
            Analytics.track(.filterCreateAsManualPlaylistTapped)

            if Settings.firstTimePlaylistCreated {
                Settings.shouldShowDragAndDropTip = true
            }

            // Dismiss all presented view controllers and show snackbar with navigation action
            if let rootVC = SceneHelper.rootViewController(includeTopMost: false) {
                rootVC.dismiss(animated: true) {
                    Toast.show(L10n.playlistEpisodesAddedToSinglePlaylist(playlist.playlistName), actions: [
                        .init(title: L10n.bookmarkAddedButtonTitle) {
                            NavigationManager.sharedManager.navigateTo(
                                NavigationManager.filterPageKey,
                                data: [
                                    NavigationManager.filterUuidKey: playlist.uuid
                                ]
                            )
                        }
                    ])
                }
            }
            return
        } else if case let .addEpisodes(episodes) = creationType {
            let didAdd = DataManager.sharedManager.add(episodes: episodes, to: playlist)
            guard didAdd else {
                let theme: any ToastTheme = ToastIconTheme(iconName: "option-alert", iconColor: Theme.sharedTheme.primaryIcon01)
                Toast.show(L10n.playlistManualCreateErrorMessage, theme: theme)
                return
            }

            Analytics.track(.addToPlaylistsCreateNewPlaylistTapped, properties: ["source": analyticsSource ?? "unknown"])

            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: playlist)

            Analytics.track(.filterCreated)
            Analytics.track(.filterCreateAsManualPlaylistTapped)

            if Settings.firstTimePlaylistCreated {
                Settings.shouldShowDragAndDropTip = true
            }

            // Dismiss all presented view controllers and show snackbar with navigation action
            if let rootVC = SceneHelper.rootViewController(includeTopMost: false) {
                rootVC.dismiss(animated: true) {
                    Toast.show(L10n.playlistEpisodesAddedToSinglePlaylist(playlist.playlistName), actions: [
                        .init(title: L10n.bookmarkAddedButtonTitle) {
                            NavigationManager.sharedManager.navigateTo(
                                NavigationManager.filterPageKey,
                                data: [
                                    NavigationManager.filterUuidKey: playlist.uuid
                                ]
                            )
                        }
                    ])
                }
            }
            return
        }

        Analytics.track(.filterCreated)
        Analytics.track(.filterCreateAsManualPlaylistTapped)

        if Settings.firstTimePlaylistCreated {
            Settings.shouldShowDragAndDropTip = true
        }

        dismiss(animated: true, completion: nil)
    }

    private func createSmartPlaylist() {
        Analytics.track(.filterCreateAsSmartPlaylistTapped)

        let playlistName = self.playlistName.isEmpty ? L10n.playlistsDefaultNewPlaylist : self.playlistName
        let createPlaylistVC = PlaylistPreviewViewController(playlistName: playlistName)
        createPlaylistVC.delegate = delegate
        let navVC = SJUIUtils.navController(for: createPlaylistVC)
        present(navVC, animated: true, completion: nil)
    }

    @objc private func closeTapped(_ sender: Any) {
        Analytics.track(.filterCreateCancelled)
        delegate?.presentingPlaylistDetail = false
        dismiss(animated: true, completion: nil)
    }

    @objc private func textFieldDidChange() {
        playlistName = playlistNameTextField.text ?? ""
    }

    private func showSmartPlaylistTooltip() {
        if creationType != .default || !Settings.shouldShowNewFilterTipInCreationView {
            return
        }

        guard
            let source = creationView,
            let vc = tip(
                title: L10n.smartPlaylistsTipViewCreationTitle,
                message: L10n.smartPlaylistsTipViewCreationDescription,
                sourceView: source,
                sourceRect: source.bounds
            )
        else {
            return
        }
        smartPlaylistsTip = vc

        present(vc, animated: true) {
            Settings.shouldShowNewFilterTipInCreationView = false
        }
    }

    private func dismissTipView() {
        smartPlaylistsTip?.dismiss(animated: true) { [weak self] in
            self?.smartPlaylistsTip = nil
        }
    }

    private func tip(
        idealSize: CGSize = CGSizeMake(290, 100),
        title: String,
        message: String,
        sourceView: UIView?,
        sourceRect: CGRect
    ) -> UIHostingController<AnyView>? {
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let tipView = TipViewStatic(title: title,
                                    message: message,
                              onTap: { [weak self] in
            self?.dismissTipView()
        })
            .frame(idealWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        vc.rootView = AnyView(tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        vc.sizingOptions = [.preferredContentSize]
        guard let popoverPresentationController = vc.popoverPresentationController else {
            return nil
        }
        popoverPresentationController.delegate = self
        popoverPresentationController.permittedArrowDirections = [.up]
        popoverPresentationController.sourceView = sourceView
        popoverPresentationController.sourceRect = sourceRect
        popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        return vc
    }
}

extension NewPlaylistViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        playlistName = ""
        return true
    }
}

extension NewPlaylistViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dismissTipView()
    }
}
