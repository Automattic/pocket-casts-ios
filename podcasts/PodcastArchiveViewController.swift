import PocketCastsDataModel
import UIKit

class PodcastArchiveViewController: PCViewController {
    @IBOutlet var archiveTable: UITableView! {
        didSet {
            registerCells()
        }
    }

    var podcast: Podcast
    var archiveSettingsChanged = false
    init(podcast: Podcast) {
        self.podcast = podcast
        super.init(nibName: "PodcastArchiveViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        changeNavTint(titleColor: nil, iconsColor: podcast.navIconTintColor(), backgroundColor: podcast.navigationBarTintColor())
        title = L10n.settingsAutoArchive
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if archiveSettingsChanged {
            ArchiveHelper.applyAutoArchivingToPodcast(podcast)
        }
    }

    override func handleThemeChanged() {
        changeNavTint(titleColor: nil, iconsColor: podcast.navIconTintColor(), backgroundColor: podcast.navigationBarTintColor())
    }
}
