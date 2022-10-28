import PocketCastsServer
import PocketCastsUtils
import UIKit

class UploadedStorageHeaderView: UIView {
    @IBOutlet var contentView: UIView!

    @IBOutlet var numFilesLabel: ThemeableLabel! {
        didSet {
            numFilesLabel.style = .primaryText02
        }
    }

    @IBOutlet var storageSizeLabel: ThemeableLabel! {
        didSet {
            storageSizeLabel.style = .primaryText02
        }
    }

    @IBOutlet var plusView: ThemeableView! {
        didSet {
            plusView.style = .primaryUi02
        }
    }

    @IBOutlet var noPlusView: ThemeableView! {
        didSet {
            noPlusView.style = .primaryUi02
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
            noPlusView.addGestureRecognizer(tapGesture)
        }
    }

    @IBOutlet var percentageLabel: ThemeableLabel!

    weak var controllerForPresenting: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("UploadedStorageHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: Constants.Notifications.themeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func headerTapped() {
        if let controllerForPresenting = controllerForPresenting {
            NavigationManager.sharedManager.showUpsellView(from: controllerForPresenting, source: .files)
        }
    }

    @objc func update() {
        if SubscriptionHelper.hasActiveSubscription() {
            plusView.isHidden = false
            noPlusView.isHidden = true

            let maxStorage = Int64(ServerSettings.customStorageUserLimit())
            let usedStorage = Int64(ServerSettings.customStorageUsed())
            let numFiles = ServerSettings.customStorageNumFiles()

            let percentageUsed = maxStorage > 0 ? Double(usedStorage) / Double(maxStorage) : 0
            numFilesLabel.text = numFiles == 1 ? L10n.profileSingleFile : L10n.profileNumberOfFiles(numFiles.localized())
            storageSizeLabel.text = "\(SizeFormatter.shared.defaultFormat(bytes: usedStorage))/ \(SizeFormatter.shared.defaultFormat(bytes: maxStorage))"
            percentageLabel.text = L10n.profilePercentFull(percentageUsed.localized(.percent))

            if percentageUsed >= 99 {
                percentageLabel.textColor = AppTheme.colorForStyle(.support05)
            } else if percentageUsed >= 90, percentageUsed < 99 {
                percentageLabel.textColor = AppTheme.colorForStyle(.support08)
            } else {
                percentageLabel.textColor = AppTheme.colorForStyle(.primaryText01)
            }
        } else {
            plusView.isHidden = true
            noPlusView.isHidden = false
        }
    }
}
