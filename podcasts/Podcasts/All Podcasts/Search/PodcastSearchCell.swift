import PocketCastsDataModel
import PocketCastsServer
import UIKit

class PodcastSearchCell: ThemeableCell {
    @IBOutlet var podcastImage: PodcastImageView!
    @IBOutlet var folderPreview: FolderPreviewView! {
        didSet {
            folderPreview.showFolderName = false
        }
    }

    @IBOutlet var podcastName: ThemeableLabel!
    @IBOutlet var podcastAuthor: ThemeableLabel! {
        didSet {
            podcastAuthor.style = .primaryText02
        }
    }

    @IBOutlet var subscribedIcon: UIImageView!

    func populateFrom(podcast: Podcast) {
        podcastName.text = podcast.title
        podcastAuthor.text = podcast.author

        podcastImage.setPodcast(uuid: podcast.uuid, size: .list)
        podcastImage.isHidden = false

        folderPreview.isHidden = true
        subscribedIcon.isHidden = false
    }

    func populateFrom(folder: Folder) {
        podcastName.text = folder.name

        let count = DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
        podcastAuthor.text = L10n.podcastCount(count)

        folderPreview.populateFromAsync(folder: folder)
        folderPreview.isHidden = false

        podcastImage.isHidden = true
        subscribedIcon.isHidden = false
    }

    func populateForm(podcastInfo: PodcastInfo) {
        if let uuid = podcastInfo.uuid {
            podcastImage.setPodcast(uuid: uuid, size: .list)
        } else {
            podcastImage.clearArtwork()
        }
        podcastName.text = podcastInfo.title
        podcastAuthor.text = podcastInfo.author

        folderPreview.isHidden = true
        subscribedIcon.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func handleThemeDidChange() {
        subscribedIcon.image = UIImage(named: "discover_tick")?.tintedImage(ThemeColor.support02())
    }
}
