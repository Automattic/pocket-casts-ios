import AVFoundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class AddCustomViewController: PCViewController, UITextFieldDelegate {
    @IBOutlet var backgroundView: ThemeableView! {
        didSet {
            backgroundView.style = .primaryUi04
        }
    }

    @IBOutlet var nameTextfield: ThemeableTextField! {
        didSet {
            nameTextfield.delegate = self
            nameTextfield.returnKeyType = .done
            nameTextfield.textStyle = .primaryText01
            nameTextfield.backgroundStyle = .primaryUi02
        }
    }

    @IBOutlet var nameLabel: ThemeableLabel! {
        didSet {
            nameLabel.style = .primaryText02
        }
    }

    @IBOutlet var sizeLabel: ThemeableLabel! {
        didSet {
            nameLabel.style = .primaryText02
        }
    }

    @IBOutlet var nameContainerView: ThemeableView! {
        didSet {
            nameContainerView.style = .primaryUi02
            nameContainerView.layer.borderWidth = 0.5
            nameContainerView.layer.borderColor = AppTheme.colorForStyle(.primaryUi05).cgColor
        }
    }

    @IBOutlet var customiseArtworkView: ThemeableView! {
        didSet {
            customiseArtworkView.style = .primaryUi02
            customiseArtworkView.layer.borderWidth = 0.5
            customiseArtworkView.layer.borderColor = AppTheme.colorForStyle(.primaryUi05).cgColor
        }
    }

    @IBOutlet var lockView: PlusLockedInfoView! {
        didSet {
            lockView.delegate = self
        }
    }

    @IBOutlet var imageBackgroundView: UIView!
    @IBOutlet var fileImageView: UIImageView! {
        didSet {
            fileImageView.layer.cornerRadius = 8
            fileImageView.clipsToBounds = true
        }
    }

    @IBOutlet var addCustomlock: UIImageView!
    @IBOutlet var addCustomImageButton: ThemeableRoundedButton! {
        didSet {
            addCustomImageButton.textStyle = .primaryInteractive01
            addCustomImageButton.buttonStyle = .primaryUi02
        }
    }

    @IBOutlet var colorPickerView: UICollectionView! {
        didSet {
            colorPickerView.contentInset = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 0)
            colorPickerView.register(UINib(nibName: "CustomStorageColorCell", bundle: nil), forCellWithReuseIdentifier: AddCustomViewController.colorCellId)
        }
    }

    @IBOutlet var errorView: ThemeableView! {
        didSet {
            errorView.style = .primaryUi01
        }
    }

    @IBOutlet var errorImageView: ThemeableImageView! {
        didSet {
            errorImageView.imageNameFunc = AppTheme.fileErrorImageName
        }
    }

    @IBOutlet var errorLabel: ThemeableLabel!
    @IBOutlet var imageSaveErrorLabel: ThemeableLabel! {
        didSet {
            imageSaveErrorLabel.style = .primaryText02
        }
    }

    @IBOutlet var scrollView: UIScrollView!
    static let colorCellId = "ColorCellId"

    let fileUrl: URL
    var name: String
    var destinationUrl: URL!
    var isVideo: Bool = false
    var fileSize: Int = 0 {
        didSet {
            if fileSize > 0 {
                let maxStorage = Int64(max(ServerSettings.customStorageUserLimit(), Constants.RemoteParams.customStorageLimitGBDefault.gigabytes))
                let usedStorage = Int64(ServerSettings.customStorageUsed())
                if usedStorage + Int64(fileSize) > maxStorage, Settings.userFilesAutoUpload() {
                    showError(message: L10n.fileUploadError + "\n" + L10n.fileUploadErrorSubtitle)
                }
            }
        }
    }

    var artwork: UIImage? {
        didSet {
            if let artworkImage = artwork {
                fileImageView.image = artworkImage // artworkImage.kf.scaled(to: 680)
                fileImageView.contentMode = .scaleAspectFit
                fileImageView.backgroundColor = AppTheme.embeddedArtworkColor()
                imageBackgroundView.backgroundColor = AppTheme.embeddedArtworkColor()
                addCustomImageButton.setTitle(L10n.fileUploadRemoveImage, for: .normal)
                colorPickerView.reloadData()
            } else {
                addCustomImageButton.setTitle(L10n.fileUploadAddImage, for: .normal)
            }
        }
    }

    var artworkNeedsUpdating = false

    var duration: TimeInterval = 0
    var selectedColor: Int = 1
    var selectedColorIndex: Int = 0 {
        didSet {
            selectedColor = artwork == nil ? selectedColorIndex + 1 : selectedColorIndex
            if selectedColor > 0 {
                fileImageView.contentMode = .scaleToFill
                ImageManager.sharedManager.imageForUserEpisodeColor(color: selectedColor, imageView: fileImageView, size: .list, completionHandler: { found in
                    if !found {
                        self.fileImageView.backgroundColor = AppTheme.userEpisodeColor(number: self.selectedColorIndex)
                    }
                })
            } else {
                if let artworkImage = artwork {
                    fileImageView.image = artworkImage.kf.scaled(to: 680)
                    fileImageView.contentMode = .scaleAspectFit
                    imageBackgroundView.backgroundColor = AppTheme.embeddedArtworkColor()
                }
            }
        }
    }

    var embeddedImage: UIImage?
    var artworkIndexPath: IndexPath?
    var greyIndexPath = IndexPath(row: 0, section: 0)
    var uuid: String
    var episodeToEdit: UserEpisode?

    required init(fileUrl: URL) {
        self.fileUrl = fileUrl
        name = fileUrl.deletingPathExtension().lastPathComponent
        uuid = UUID().uuidString.lowercased()
        selectedColor = 1
        super.init(nibName: nil, bundle: nil)
    }

    required init(episode: UserEpisode) {
        uuid = episode.uuid
        fileUrl = URL(fileURLWithPath: DownloadManager.shared.pathForEpisode(episode))
        episodeToEdit = episode
        name = episode.title ?? ""
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("AddCUstomViewController init(coder) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let mainView = view as? ThemeableView {
            mainView.style = .primaryUi04
        }
        setupColorPicker()
        if let episode = episodeToEdit {
            title = L10n.fileUploadEditFile
            nameTextfield.text = name
            nameLabel.text = name
            fileSize = Int(episode.sizeInBytes)
            sizeLabel.text = SizeFormatter.shared.defaultFormat(bytes: Int64(fileSize))

            if episode.imageColor == 0 {
                ImageManager.sharedManager.imageForEpisode(episode, size: .list) { [weak self] image in
                    self?.artwork = image
                }
            } else {
                selectedColorIndex = Int(episode.imageColor) - 1
                artwork = nil
            }

            imageSaveErrorLabel.isHidden = true
            errorView.isHidden = true
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
            navigationItem.leftBarButtonItem = cancelButton

            colorPickerView.selectItem(at: IndexPath(item: selectedColorIndex, section: 0), animated: false, scrollPosition: .left)
            view.backgroundColor = AppTheme.uploadProgressBackgroundColor()

            nameTextfield.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            setupScrollViewOffset()
            setupUserAccess()
        } else {
            guard FileTypeUtil.isSupportedUserFileType(fileName: fileUrl.absoluteString) else {
                showError(message: L10n.fileUploadSupportError)
                return
            }
            if let newFileLocation = DownloadManager.shared.addLocalFile(url: fileUrl, uuid: uuid) {
                destinationUrl = newFileLocation
                title = L10n.fileUploadAddFile
                errorView.isHidden = true
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
                navigationItem.leftBarButtonItem = cancelButton

                view.backgroundColor = AppTheme.uploadProgressBackgroundColor()

                nameTextfield.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                setupFileDetails()
                imageSaveErrorLabel.isHidden = true
                setupScrollViewOffset()
            } else {
                showError(message: L10n.pleaseTryAgain) // TODO: update error meessage
            }
        }

        addCustomObserver(ServerNotifications.subscriptionStatusChanged, selector: #selector(setupUserAccess))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        colorPickerView.selectItem(at: IndexPath(item: selectedColorIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        let saveButton = UIBarButtonItem(title: L10n.fileUploadSave, style: .plain, target: self, action: #selector(saveTapped))
        customRightBtn = saveButton
    }

    // MARK: Private helpers

    private func setupScrollViewOffset() {
        let existingInset = scrollView.contentInset
        scrollView.contentInset = UIEdgeInsets(top: existingInset.top, left: existingInset.left, bottom: existingInset.bottom + Constants.Values.miniPlayerOffset, right: existingInset.right)
    }

    private var avFileUtil: AVFileUtil?
    private func setupFileDetails() {
        avFileUtil = AVFileUtil(fileURL: destinationUrl, durationHandler: { duration in
            self.duration = duration
        }, titleHandler: { embeddedName in
            if let embeddedName = embeddedName {
                self.name = embeddedName
            }
            DispatchQueue.main.async {
                self.nameTextfield.text = self.name
                self.nameLabel.text = self.name
            }
        }, artworkHandler: { image in
            DispatchQueue.main.async {
                self.embeddedImage = image
                self.artwork = image
                self.selectedColorIndex = 0
                self.colorPickerView.reloadData()
                self.colorPickerView.selectItem(at: IndexPath(item: self.selectedColorIndex, section: 0), animated: false, scrollPosition: .left)
                self.setupUserAccess()
            }
        })

        DispatchQueue.main.async {
            do {
                let resources = try self.destinationUrl.resourceValues(forKeys: [.fileSizeKey])
                self.fileSize = resources.fileSize ?? 0
                self.sizeLabel.text = SizeFormatter.shared.defaultFormat(bytes: Int64(self.fileSize))
            } catch {}
        }
    }

    private lazy var lockedArtworkTapGesture = UITapGestureRecognizer(target: self, action: #selector(showSubscriptionRequired))

    @objc private func setupUserAccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if SubscriptionHelper.hasActiveSubscription() {
                self.addCustomlock.isHidden = true
                self.lockView.isHidden = true
                self.addCustomImageButton.alpha = 1
            } else {
                self.addCustomImageButton.setTitle(L10n.fileUploadAddImage, for: .normal)
                self.addCustomImageButton.isEnabled = true
                self.addCustomlock.isHidden = false
                self.lockView.isHidden = Settings.plusInfoDismissedOnFilesAdd()

                if self.embeddedImage == nil {
                    self.customiseArtworkView.addGestureRecognizer(self.lockedArtworkTapGesture)
                    self.customiseArtworkView.alpha = 0.3
                } else {
                    self.customiseArtworkView.removeGestureRecognizer(self.lockedArtworkTapGesture)
                    self.customiseArtworkView.alpha = 1
                    self.addCustomImageButton.alpha = 0.3
                }
            }
        }
    }

    // MARK: Actions

    @IBAction func cancelTapped() {
        navigationController?.navigationBar.isHidden = false
        if episodeToEdit == nil {
            if let destinationUrl = destinationUrl {
                StorageManager.removeItem(at: destinationUrl)
            }
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func saveTapped() {
        nameTextfield.resignFirstResponder()
        nameTextfield.isHidden = true
        imageSaveErrorLabel.isHidden = true

        let selectedColor = greyIndexPath.item == 0 ? selectedColorIndex + 1 : selectedColorIndex

        if let episodeToEdit = episodeToEdit {
            if artworkNeedsUpdating {
                do {
                    try UserEpisodeManager.updateUserEpisodeImage(uuid: episodeToEdit.uuid, artwork: artwork, completion: {
                        UserEpisodeManager.updateUserEpisode(uuid: episodeToEdit.uuid, title: self.name, color: selectedColor)
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                        WidgetHelper.shared.updateCustomImage(userEpisode: episodeToEdit)
                    })
                } catch {
                    imageSaveErrorLabel.isHidden = false
                    return
                }
            } else {
                UserEpisodeManager.updateUserEpisode(uuid: episodeToEdit.uuid, title: name, color: selectedColor)

                navigationController?.popViewController(animated: true)
            }
        } else {
            do {
                _ = try UserEpisodeManager.addUserEpisode(uuid: uuid, title: name, localFileUrl: destinationUrl, artwork: artwork, color: selectedColor, fileSize: fileSize, duration: duration)
                dismiss(animated: true, completion: nil)
            } catch {
                imageSaveErrorLabel.isHidden = false
            }
        }
    }

    @IBAction func addCustomImageClicked(_ sender: Any) {
        guard SubscriptionHelper.hasActiveSubscription() else {
            showSubscriptionRequired()
            return
        }

        if artwork == nil { // add imgage
            // Check permissions and add the actions
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                showAddImagePicker(hasCameraAccess: true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    // as per the documentation: The completion handler is called on an arbitrary dispatch queue. It is the client's responsibility to ensure that any UIKit-related updates are called on the main queue or main thread as a result.
                    DispatchQueue.main.async {
                        self.showAddImagePicker(hasCameraAccess: granted)
                    }
                }
            default:
                showAddImagePicker(hasCameraAccess: false)
            }
        } else { // remove image
            artwork = nil
            artworkNeedsUpdating = true
            colorPickerView.reloadData()
            if selectedColorIndex > 0 {
                selectedColorIndex = selectedColorIndex - 1
            } else {
                selectedColorIndex = 0
            }
            colorPickerView.selectItem(at: IndexPath(item: selectedColorIndex, section: 0), animated: false, scrollPosition: .left)
        }
    }

    private func showAddImagePicker(hasCameraAccess: Bool) {
        let optionPicker = OptionsPicker(title: L10n.fileUploadChooseImage)

        if hasCameraAccess {
            let cameraAction = OptionAction(label: L10n.fileUploadChooseImageCamera, icon: nil) {
                self.showCamera()
            }
            optionPicker.addAction(action: cameraAction)
        }

        let libraryAction = OptionAction(label: L10n.fileUploadChooseImagePhotoLibrary, icon: nil) {
            self.showPhotoLibrary()
        }
        optionPicker.addAction(action: libraryAction)

        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func showError(message: String) {
        navigationController?.navigationBar.isHidden = true
        errorLabel.text = message
        errorView.isHidden = false
    }

    override func handleThemeChanged() {
        customiseArtworkView.layer.borderColor = AppTheme.colorForStyle(.primaryUi05).cgColor
        nameContainerView.layer.borderColor = AppTheme.colorForStyle(.primaryUi05).cgColor
        colorPickerView.reloadData()
        colorPickerView.selectItem(at: IndexPath(item: selectedColorIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }

    // MARK: Textfield delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
        textField.resignFirstResponder()
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        if let typedText = nameTextfield.text, typedText.count > 0 {
            nameLabel.text = typedText
            name = typedText
            nameLabel.style = .primaryText02
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            nameLabel.text = L10n.fileUploadNameRequired
            nameLabel.style = .support05
        }
    }

    @objc func showSubscriptionRequired() {
        NavigationManager.sharedManager.showUpsellView(from: self, source: .files)
    }
}

// MARK: Plus Locked Info Delegate

extension AddCustomViewController: PlusLockedInfoDelegate {
    func closeInfoTapped() {
        lockView.isHidden = true
        Settings.setPlusInfoDismissedOnFilesAdd(true)
    }

    var displayingViewController: UIViewController {
        self
    }

    var displaySource: PlusUpgradeViewSource {
        .files
    }
}
