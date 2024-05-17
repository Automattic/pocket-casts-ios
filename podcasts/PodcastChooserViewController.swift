import PocketCastsDataModel
import UIKit

@objc protocol PodcastSelectionDelegate: AnyObject {
    func bulkSelectionChange(selected: Bool)
    func podcastSelected(podcast: String)
    func podcastUnselected(podcast: String)
    func didChangePodcasts()
}

class PodcastChooserViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let cellId = "PodcastChooserCell"

    var selectedUuidsUpdated = false
    weak var delegate: PodcastSelectionDelegate?
    var selectedUuids = [String]()
    var selectAllOnLoad = false
    var allowSelectAll = true

    private var didChange = false

    @IBOutlet var podcastTable: UITableView! {
        didSet {
            podcastTable.register(UINib(nibName: "PodcastChooserCell", bundle: nil), forCellReuseIdentifier: cellId)
        }
    }

    var allPodcasts = [Podcast]()
    var selectBtn: UIBarButtonItem!

    override func viewDidLoad() {
        selectBtn = UIBarButtonItem(title: L10n.selectAll, style: .plain, target: self, action: #selector(selectBtnTapped))
        if allowSelectAll {
            customRightBtn = selectBtn
        }
        super.viewDidLoad()

        title = L10n.shareSelectPodcasts

        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: podcastTable)

        loadPodcasts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if selectedUuidsUpdated {
            selectedUuidsUpdated = false
            loadPodcasts()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if didChange {
            delegate?.didChangePodcasts()
        }
    }

    // MARK: - UITableView Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allPodcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let podcastCell = cell as! PodcastChooserCell

        let podcast = allPodcasts[indexPath.row]
        podcastCell.podcastName.text = podcast.title
        podcastCell.setIsSelected(selectedUuids.contains(podcast.uuid))
        podcastCell.podcastImage.setPodcast(uuid: podcast.uuid, size: .list)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let podcastUuid = allPodcasts[indexPath.row].uuid
        let index = selectedUuids.firstIndex(of: podcastUuid)
        if let index = index {
            selectedUuids.remove(at: index)

            // to support things like playlist editting that need to know about all/none selected events send a different event when it gets to 0
            if selectedUuids.count == 0, allowSelectAll {
                delegate?.bulkSelectionChange(selected: false)
            } else {
                delegate?.podcastUnselected(podcast: podcastUuid)
            }
        } else {
            selectedUuids.append(podcastUuid)

            // to support things like playlist editting that need to know about all/none selected events send a different event when all are manually selected
            if selectedUuids.count == allPodcasts.count, allowSelectAll {
                delegate?.bulkSelectionChange(selected: true)
            } else {
                delegate?.podcastSelected(podcast: podcastUuid)
            }
        }

        tableView.reloadRows(at: [indexPath], with: .none)
        updateSelectBtn()

        didChange = true
    }

    private func loadPodcasts() {
        allPodcasts = DataManager.sharedManager.allPodcastsOrderedByTitle()

        if selectAllOnLoad {
            selectedUuids = allPodcasts.map(\.uuid)
        }

        podcastTable.reloadData()
        updateSelectBtn()
    }

    func updateSelectBtn() {
        selectBtn.title = shouldSelectAll() ? L10n.selectAll : L10n.deselectAll
    }

    @objc private func selectBtnTapped() {
        if shouldSelectAll() {
            selectedUuids = allPodcasts.map(\.uuid)
            delegate?.bulkSelectionChange(selected: true)
        } else {
            selectedUuids.removeAll()
            delegate?.bulkSelectionChange(selected: false)
        }

        podcastTable.reloadData()
        updateSelectBtn()
        didChange = true
    }

    private func shouldSelectAll() -> Bool {
        let onCount = selectedUuids.count
        let offCount = allPodcasts.count - onCount

        return onCount < offCount
    }
}
