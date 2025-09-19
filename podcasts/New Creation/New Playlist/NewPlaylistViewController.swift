import UIKit
import PocketCastsDataModel

class NewPlaylistViewController: PCViewController {
    weak var delegate: FilterCreatedDelegate?

    private var playlistName: String = ""
    private var playlistNameTextField: ThemeableTextField! {
        didSet {
            playlistNameTextField.translatesAutoresizingMaskIntoConstraints = false
            playlistNameTextField.placeholder = L10n.playlistsDefaultNewPlaylist
            playlistNameTextField.placeholderStyle = .primaryText01
            playlistNameTextField.delegate = self
            playlistNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
            playlistNameTextField.clearsOnBeginEditing = true
            playlistNameTextField.clearButtonMode = .whileEditing
            playlistNameTextField.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
            playlistNameTextField.font = .systemFont(ofSize: 15, weight: .medium)
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
            setupSaveButtonTitle()
            saveButton.layer.cornerRadius = 12
            saveButton.addTarget(self, action: #selector(createManualPlaylist), for: .touchUpInside)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        addCloseButton()
        setupContent()
    }

    private func setupNavBar() {
        let backgroundColor = AppTheme.viewBackgroundColor()
        changeNavTint(titleColor: AppTheme.colorForStyle(.primaryText01), iconsColor: AppTheme.colorForStyle(.primaryIcon03), backgroundColor: backgroundColor)

        title = L10n.playlistsDefaultNewPlaylist

        largeTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)

        navigationController?.navigationBar.prefersLargeTitles = true

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

        let creationView = SmartPlaylistCreationView() { [weak self] in
            self?.createSmartPlaylist()
        }.themedUIView
        creationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(creationView)

        saveButton = UIButton(type: .custom)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            textFieldBorderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10.0),
            textFieldBorderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            textFieldBorderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            textFieldBorderView.heightAnchor.constraint(equalToConstant: 56.0),

            playlistNameTextField.topAnchor.constraint(equalTo: textFieldBorderView.topAnchor),
            playlistNameTextField.leadingAnchor.constraint(equalTo: textFieldBorderView.leadingAnchor, constant: 16.0),
            playlistNameTextField.trailingAnchor.constraint(equalTo: textFieldBorderView.trailingAnchor, constant: -16.0),
            playlistNameTextField.bottomAnchor.constraint(equalTo: textFieldBorderView.bottomAnchor),

            creationView.topAnchor.constraint(equalTo: textFieldBorderView.bottomAnchor, constant: 16.0),
            creationView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
            creationView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
            creationView.heightAnchor.constraint(equalToConstant: 59.0),

            saveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            saveButton.topAnchor.constraint(equalTo: creationView.bottomAnchor, constant: 24),
            saveButton.heightAnchor.constraint(equalToConstant: 56.0)
        ])

        view.layoutSubviews()
    }

    private func addCloseButton() {
        let closeButton = createStandardCloseButton(imageName: "cancel")
        closeButton.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)

        let backButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }

    private func setupSaveButtonTitle() {
        let attributedTitle = NSAttributedString(string: L10n.playlistCreationCreatePlaylistButton, attributes: [NSAttributedString.Key.foregroundColor: ThemeColor.primaryInteractive02(), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)])
        saveButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    @objc private func createManualPlaylist() {
        let playlistName = self.playlistName.isEmpty ? L10n.playlistsDefaultNewPlaylist : self.playlistName
        let playlist = PlaylistManager.createNewFilter()
        playlist.setTitle(playlistName, defaultTitle: L10n.playlistsDefaultNewPlaylist.localizedCapitalized)
        playlist.manual = true
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        playlist.isNew = false

        let episodes = DataManager.sharedManager.allUpNextEpisodes().compactMap { baseEpisode in
            let episode = DataManager.sharedManager.findEpisode(uuid: baseEpisode.uuid)
            return episode
        }
        DataManager.sharedManager.add(episodes: episodes, to: playlist)

        DataManager.sharedManager.save(filter: playlist)
        UserDefaults.standard.set(playlist.uuid, forKey: Constants.UserDefaults.lastFilterShown)
        delegate?.filterCreated(newFilter: playlist)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: playlist)

        //TODO: Add analytics for manual playlist creation

        dismiss(animated: true, completion: nil)
    }

    private func createSmartPlaylist() {
        let playlistName = self.playlistName.isEmpty ? L10n.playlistsDefaultNewPlaylist : self.playlistName
        let createPlaylistVC = PlaylistPreviewViewController(playlistName: playlistName)
        createPlaylistVC.delegate = delegate
        let navVC = SJUIUtils.navController(for: createPlaylistVC)
        present(navVC, animated: true, completion: nil)
    }

    @objc private func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func textFieldDidChange() {
        playlistName = playlistNameTextField.text ?? ""
    }
}

extension NewPlaylistViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        playlistName = ""
        return true
    }
}
