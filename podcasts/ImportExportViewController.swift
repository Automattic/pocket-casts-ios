import PocketCastsDataModel
import PocketCastsServer
import UIKit

class ImportExportViewController: PCViewController, UIDocumentInteractionControllerDelegate {
    private var loadingAlert: ShiftyLoadingAlert?

    private var opmlShareController: UIDocumentInteractionController?

    @IBOutlet var importPocdcastsTitle: UILabel! {
        didSet {
            importPocdcastsTitle.text = L10n.importPodcastsTitle.localizedUppercase
        }
    }

    @IBOutlet var importPodcastsDescription: ThemeableLabel! {
        didSet {
            importPodcastsDescription.text = L10n.importPodcastsDescription
        }
    }

    @IBOutlet var exportPodcastsTitle: UILabel! {
        didSet {
            exportPodcastsTitle.text = L10n.exportPodcastsTitle.localizedUppercase
        }
    }

    @IBOutlet var exportPodcastsDescription: ThemeableLabel! {
        didSet {
            exportPodcastsDescription.text = L10n.exportPodcastsDescription
        }
    }

    @IBOutlet var importView: ThemeableView! {
        didSet {
            importView.style = .primaryUi01Active
        }
    }

    @IBOutlet var exportView: ThemeableView! {
        didSet {
            exportView.style = .primaryUi01Active
        }
    }

    @IBOutlet var importImage: UIImageView! {
        didSet {
            importImage.image = Theme.isDarkTheme() ? UIImage(named: "settings_importillustration_dark") : UIImage(named: "settings_importillustration")
        }
    }

    @IBOutlet var exportBtn: UIButton! {
        didSet {
            exportBtn.setTitle(L10n.exportPodcastsOption, for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsImportExport
    }

    @IBOutlet var mainScrollView: UIScrollView!

    @IBAction func exportPodcasts(_ sender: AnyObject) {
        loadingAlert = ShiftyLoadingAlert(title: L10n.settingsExportOpml)
        loadingAlert?.showAlert(self, hasProgress: false, completion: {
            self.startExport()
        })
    }

    private func startExport() {
        let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

        let uuids = podcasts.map(\.uuid)

        MainServerHandler.shared.exportPodcasts(uuids: uuids) { exportResponse in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.loadingAlert?.hideAlert(false)
                self.loadingAlert = nil

                guard let exportResponse = exportResponse, exportResponse.success(), let mapping = exportResponse.result else {
                    self.presentError()
                    return
                }

                self.performOpmlExport(podcasts, mappingDictionary: mapping)
            }
        }
    }

    private func performOpmlExport(_ podcasts: [Podcast], mappingDictionary: [String: String]) {
        let exportXML = AEXMLDocument()
        let opml = exportXML.addChild(name: "opml", attributes: ["version": "1.0"])
        let header = opml.addChild(name: "head")
        _ = header.addChild(name: "title", value: "Pocket Casts Feeds")

        let body = opml.addChild(name: "body")
        let outline = body.addChild(name: "outline", attributes: ["text": "feeds"])
        for podcast in podcasts {
            let podcastTitle = podcast.title ?? ""
            let urlToUse = mappingDictionary[podcast.uuid] ?? ""
            _ = outline.addChild(name: "outline", attributes: ["type": "rss", "text": podcastTitle, "xmlUrl": urlToUse])
        }

        shareOpmlDocument(exportXML)
    }

    private func shareOpmlDocument(_ document: AEXMLDocument) {
        let text = document.xmlString
        let homeDirectory = NSTemporaryDirectory() as NSString
        let filePath = homeDirectory.appendingPathComponent("podcasts.opml")
        do {
            try text.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)

            let fileUrl = URL(fileURLWithPath: filePath)
            opmlShareController = UIDocumentInteractionController(url: fileUrl)
            opmlShareController?.delegate = self

            let presentRect = view.convert(exportBtn.frame, from: exportBtn.superview)
            opmlShareController?.presentOptionsMenu(from: presentRect, in: view, animated: true)
        } catch {
            presentError()
        }
    }

    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        opmlShareController = nil
    }

    private func presentError() {
        SJUIUtils.showAlert(title: L10n.settingsExportError, message: L10n.settingsExportErrorMsg, from: self)
    }
}
